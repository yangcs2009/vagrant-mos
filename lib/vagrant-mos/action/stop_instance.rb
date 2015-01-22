require "log4r"

module VagrantPlugins
  module MOS
    module Action
      # This stops the running instance.
      class StopInstance
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_mos::action::stop_instance")
        end

        def call(env)
          if env[:machine].state.id == "ready"
            env[:ui].info(I18n.t("vagrant_mos.already stopped"))
          else
            env[:ui].info(I18n.t("vagrant_mos.stopping"))
            env[:mos_compute].stop_instance(env[:machine].id)
          end

          @app.call(env)
        end
      end
    end
  end
end
