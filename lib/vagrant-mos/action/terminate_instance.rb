require "log4r"
require "json"

module VagrantPlugins
  module MOS
    module Action
      # This terminates the running instance.
      class TerminateInstance
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_mos::action::terminate_instance")
        end

        def call(env)
          # Destroy the server and remove the tracking ID
          env[:ui].info(I18n.t("vagrant_mos.terminating"))
          env[:mos_compute].terminate_instance(env[:machine].id)
          env[:machine].id = nil

          @app.call(env)
        end
      end
    end
  end
end
