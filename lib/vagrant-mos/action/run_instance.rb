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
          name = region_config.name
          instance_type = region_config.instance_type
          keypair = region_config.keypair_name
          terminate_on_shutdown = region_config.terminate_on_shutdown

          # If there is no keypair then warn the user
          if !keypair
            env[:ui].warn(I18n.t("vagrant_mos.launch_no_keypair"))
          end

          # Launch!
          env[:ui].info(I18n.t("vagrant_mos.launching_instance"))
          env[:ui].info(" -- Name: #{name}") if name
          env[:ui].info(" -- Type: #{instance_type}")
          env[:ui].info(" -- AMI: #{ami}")
          env[:ui].info(" -- Region: #{region}")
          env[:ui].info(" -- Keypair: #{keypair}") if keypair
          env[:ui].info(" -- Terminate On Shutdown: #{terminate_on_shutdown}")

          options = {
              :flavor_id => instance_type,
              :name => name,
              :image_id => ami,
              :key_name => keypair,
              :instance_initiated_shutdown_behavior => terminate_on_shutdown == true ? "terminate" : nil,
          }

          begin
            # create a handler to access MOS
            server = env[:mos_compute].create_instance(options[:image_id], options[:flavor_id], nil, options[:name], options[:key_name], datadisk=9, bandwidth=2)
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
