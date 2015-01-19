module VagrantPlugins
  module MOS
    module Action
      class MessageAlreadyCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info(I18n.t("vagrant_mos.already_status", :status => "created"))
          @app.call(env)
        end
      end
    end
  end
end
