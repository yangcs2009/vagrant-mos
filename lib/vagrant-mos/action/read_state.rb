require "log4r"

module VagrantPlugins
  module MOS
    module Action
      # This action reads the state of the machine and puts it in the
      # `:machine_state_id` key in the environment.
      class ReadState
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant_mos::action::read_state")
        end

        def call(env)
          env[:machine_state_id] = read_state(env[:mos_compute], env[:machine])

          @app.call(env)
        end

        def read_state(mos, machine)
          return :not_created if machine.id.nil?

          # Find the machine
          #puts mos
          #puts machine.id
          server = (mos.describe_instances([machine.id]))["Instance"]
          #puts "read_state"
          #puts server
          #puts "finish read_state"
          #server = mos.servers.get(machine.id)
          if server.nil? || [:"shutting-down", :terminated].include?(server["status"])
            # The machine can't be found
            @logger.info("Machine not found or terminated, assuming it got destroyed.")
            machine.id = nil
            return :not_created
          end

          # Return the state
          # puts server["status"]
          return server["status"]

        end
      end
    end
  end
end
