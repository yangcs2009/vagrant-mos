require "log4r"

require 'vagrant/util/retryable'

require 'vagrant-mos/util/timer'

module VagrantPlugins
  module MOS
    module Action
      # This starts a stopped instance.
      class StartInstance
        include Vagrant::Util::Retryable

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_mos::action::start_instance")
        end

        def call(env)
          # Initialize metrics if they haven't been
          env[:metrics] ||= {}

          #server = env[:mos_compute].servers.get(env[:machine].id)
          server = (env[:mos_compute].describe_instances([env[:machine].id]))["Instance"]
          env[:ui].info(I18n.t("vagrant_mos.starting"))

          begin
            #server.start
            env[:mos_compute].start_instance(env[:machine].id)

            region = env[:machine].provider_config.region
            region_config = env[:machine].provider_config.get_region_config(region)

            # Wait for the instance to be ready first
            env[:metrics]["instance_ready_time"] = Util::Timer.time do
              tries = region_config.instance_ready_timeout / 2

              env[:ui].info(I18n.t("vagrant_mos.waiting_for_ready"))
              begin
                retryable(:on => Errors::InstanceReadyTimeout, :tries => tries) do
                  # If we're interrupted don't worry about waiting
                  next if env[:interrupted]

                  # Wait for the server to be ready
                  #server.wait_for(2) { ready? }
                  if(server["status"] == "running")
                    break
                  else
                    sleep(2)
                  end
                end
              rescue Errors::InstanceReadyTimeout
                # Notify the user
                raise Errors::InstanceReadyTimeout,
                  timeout: region_config.instance_ready_timeout
              end
            end
          rescue MOS::Error => e
            raise Errors::MosError, :message => e.message
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

          @app.call(env)
        end
      end
    end
  end
end
