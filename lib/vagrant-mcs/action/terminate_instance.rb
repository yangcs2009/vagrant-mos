require "log4r"
require "json"

module VagrantPlugins
  module MCS
    module Action
      # This terminates the running instance.
      class TerminateInstance
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_mcs::action::terminate_instance")
        end

        def call(env)
          server         = env[:mcs_compute].describe_instances(env[:machine].id)
          region         = env[:machine].provider_config.region
          region_config  = env[:machine].provider_config.get_region_config(region)

          elastic_ip     = region_config.elastic_ip

          # Release the elastic IP
          ip_file = env[:machine].data_dir.join('elastic_ip')
          if ip_file.file?
            release_address(env,ip_file.read)
            ip_file.delete
          end

          # Destroy the server and remove the tracking ID
          env[:ui].info(I18n.t("vagrant_mcs.terminating"))
          #server.destroy
          env[:mcs_compute].terminate_instance(env[:machine].id)
          env[:machine].id = nil

          @app.call(env)
        end

        # Release an elastic IP address
        def release_address(env,eip)
          h = JSON.parse(eip)
          # Use association_id and allocation_id for VPC, use public IP for EC2
          if h['association_id']
            env[:mcs_compute].disassociate_address(nil,h['association_id'])
            env[:mcs_compute].release_address(h['allocation_id'])
          else
            env[:mcs_compute].disassociate_address(h['public_ip'])
            env[:mcs_compute].release_address(h['public_ip'])
          end
        end
      end
    end
  end
end
