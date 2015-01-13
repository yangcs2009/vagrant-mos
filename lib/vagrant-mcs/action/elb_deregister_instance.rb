require 'vagrant-mcs/util/elb'

module VagrantPlugins
  module MCS
    module Action
      # This registers instance in ELB
      class ElbDeregisterInstance
        include ElasticLoadBalancer

        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_mcs::action::elb_deregister_instance")
        end

        def call(env)
          if elb_name = env[:machine].provider_config.elb
            deregister_instance env, elb_name, env[:machine].id
          end
          @app.call(env)
        end
      end
    end
  end
end
