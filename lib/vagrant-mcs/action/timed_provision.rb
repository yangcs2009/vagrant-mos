require "vagrant-mcs/util/timer"

module VagrantPlugins
  module MCS
    module Action
      # This is the same as the builtin provision except it times the
      # provisioner runs.
      class TimedProvision < Vagrant::Action::Builtin::Provision
        def run_provisioner(env, name, p)
          timer = Util::Timer.time do
            super
          end

          env[:metrics] ||= {}
          env[:metrics]["provisioner_times"] ||= []
          env[:metrics]["provisioner_times"] << [name, timer]
        end
      end
    end
  end
end
