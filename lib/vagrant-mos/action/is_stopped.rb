module VagrantPlugins
  module MOS
    module Action
      # This can be used with "Call" built-in to check if the machine
      # is stopped and branch in the middleware.
      class IsStopped
        def initialize(app, env)
          @app = app
        end

        def call(env)
          puts env[:machine].state.id
          env[:result] = env[:machine].state.id == "ready"
          @app.call(env)
        end
      end
    end
  end
end
