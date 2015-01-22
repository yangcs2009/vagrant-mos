require "log4r"
require 'json'

require 'vagrant/util/retryable'

require 'vagrant-mos/util/timer'

module VagrantPlugins
  module MOS
    module Action
      # This runs the configured instance.
      class RunInstance
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_mos::action::run_instance")
        end

        def call(env)
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          # Get the region we're going to booting up in
          region = env[:machine].provider_config.region

          # Get the configs
          region_config = env[:machine].provider_config.get_region_config(region)
          ami = region_config.ami
          availability_zone = region_config.availability_zone
          instance_type = region_config.instance_type
          keypair = region_config.keypair_name
          private_ip_address = region_config.private_ip_address
          security_groups = region_config.security_groups
          subnet_id = region_config.subnet_id
          tags = region_config.tags
          user_data = region_config.user_data
          block_device_mapping = region_config.block_device_mapping
          #elastic_ip = region_config.elastic_ip
          terminate_on_shutdown = region_config.terminate_on_shutdown
          iam_instance_profile_arn = region_config.iam_instance_profile_arn
          iam_instance_profile_name = region_config.iam_instance_profile_name
          monitoring = region_config.monitoring
          #ebs_optimized = region_config.ebs_optimized
          associate_public_ip = region_config.associate_public_ip

          # If there is no keypair then warn the user
          if !keypair
            env[:ui].warn(I18n.t("vagrant_mos.launch_no_keypair"))
          end

          # Launch!
          env[:ui].info(I18n.t("vagrant_mos.launching_instance"))
          env[:ui].info(" -- Type: #{instance_type}")
          env[:ui].info(" -- AMI: #{ami}")
          env[:ui].info(" -- Region: #{region}")
          env[:ui].info(" -- Availability Zone: #{availability_zone}") if availability_zone
          env[:ui].info(" -- Keypair: #{keypair}") if keypair
          env[:ui].info(" -- Subnet ID: #{subnet_id}") if subnet_id
          env[:ui].info(" -- IAM Instance Profile ARN: #{iam_instance_profile_arn}") if iam_instance_profile_arn
          env[:ui].info(" -- IAM Instance Profile Name: #{iam_instance_profile_name}") if iam_instance_profile_name
          env[:ui].info(" -- Private IP: #{private_ip_address}") if private_ip_address
          env[:ui].info(" -- User Data: yes") if user_data
          env[:ui].info(" -- Security Groups: #{security_groups.inspect}") if !security_groups.empty?
          env[:ui].info(" -- User Data: #{user_data}") if user_data
          env[:ui].info(" -- Block Device Mapping: #{block_device_mapping}") if block_device_mapping
          env[:ui].info(" -- Terminate On Shutdown: #{terminate_on_shutdown}")
          env[:ui].info(" -- Monitoring: #{monitoring}")
          env[:ui].info(" -- Assigning a public IP address in a VPC: #{associate_public_ip}")

          options = {
              :availability_zone => availability_zone,
              :flavor_id => instance_type,
              :image_id => ami,
              :key_name => keypair,
              :private_ip_address => private_ip_address,
              :subnet_id => subnet_id,
              :iam_instance_profile_arn => iam_instance_profile_arn,
              :iam_instance_profile_name => iam_instance_profile_name,
              :tags => tags,
              :user_data => user_data,
              :block_device_mapping => block_device_mapping,
              :instance_initiated_shutdown_behavior => terminate_on_shutdown == true ? "terminate" : nil,
              :monitoring => monitoring,
              #:ebs_optimized => ebs_optimized,
              :associate_public_ip => associate_public_ip
          }
          if !security_groups.empty?
            security_group_key = options[:subnet_id].nil? ? :groups : :security_group_ids
            options[security_group_key] = security_groups
            env[:ui].warn(I18n.t("vagrant_mos.warn_ssh_access")) unless allows_ssh_port?(env, security_groups, subnet_id)
          end

          begin
            # todo
            server = env[:mos_compute].create_instance(options[:image_id], options[:flavor_id], nil, nil, options[:key_name], datadisk=9, bandwidth=2)
          rescue Exception => e
            raise Errors::MosError, :message => e.message
          end

          # Immediately save the ID since it is created at this point.
          env[:machine].id = server['instanceId']

          # Wait for the instance to be ready first
          env[:metrics]["instance_ready_time"] = Util::Timer.time do
            tries = region_config.instance_ready_timeout / 2

            env[:ui].info(I18n.t("vagrant_mos.waiting_for_ready"))
            begin
              retryable(:on => Errors::InstanceReadyTimeout, :tries => tries) do
                # If we're interrupted don't worry about waiting
                next if env[:interrupted]

                # Wait for the server to be ready
                #server.wait_for(2, 5) { ready? }
                if(server["status"] == "running")
                  break
                else
                  sleep(2)
                end
              end
            rescue Errors::InstanceReadyTimeout
              # Delete the instance
              terminate(env)

              # Notify the user
              raise Errors::InstanceReadyTimeout,
                    timeout: region_config.instance_ready_timeout
            end
          end

          @logger.info("Time to instance ready: #{env[:metrics]["instance_ready_time"]}")

          if !env[:interrupted]
            env[:metrics]["instance_ssh_time"] = Util::Timer.time do
              # Wait for SSH to be ready.
              env[:ui].info(I18n.t("vagrant_mos.waiting_for_ssh"))
              while true
                # If we're interrupted then just back out
                break if env[:interrupted]
                break if env[:machine].communicate.ready?
                sleep 2
              end
            end

            @logger.info("Time for SSH ready: #{env[:metrics]["instance_ssh_time"]}")

            # Ready and booted!
            env[:ui].info(I18n.t("vagrant_mos.ready"))
          end

          # Terminate the instance if we were interrupted
          terminate(env) if env[:interrupted]

          @app.call(env)
        end

        def recover(env)
          return if env["vagrant.error"].is_a?(Vagrant::Errors::VagrantError)

          if env[:machine].provider.state.id != :not_created
            # Undo the import
            terminate(env)
          end
        end

        def allows_ssh_port?(env, test_sec_groups, is_vpc)
          port = 22 # TODO get ssh_info port
          test_sec_groups = ["default"] if test_sec_groups.empty? # MOS default security group
                    # filter groups by name or group_id (vpc)
          groups = test_sec_groups.map do |tsg|
            env[:mos_compute].security_groups.all.select { |sg| tsg == (is_vpc ? sg.group_id : sg.name) }
          end.flatten
                    # filter TCP rules
          rules = groups.map { |sg| sg.ip_permissions.select { |r| r["ipProtocol"] == "tcp" } }.flatten
                    # test if any range includes port
          !rules.select { |r| (r["fromPort"]..r["toPort"]).include?(port) }.empty?
        end

        def terminate(env)
          destroy_env = env.dup
          destroy_env.delete(:interrupted)
          destroy_env[:config_validate] = false
          destroy_env[:force_confirm_destroy] = true
          env[:action_runner].run(Action.action_destroy, destroy_env)
        end
      end
    end
  end
end
