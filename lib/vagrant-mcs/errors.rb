require "vagrant"

module VagrantPlugins
  module MCS
    module Errors
      class VagrantMCSError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_mcs.errors")
      end

      class FogError < VagrantMCSError
        error_key(:fog_error)
      end

      class InternalFogError < VagrantMCSError
        error_key(:internal_fog_error)
      end

      class InstanceReadyTimeout < VagrantMCSError
        error_key(:instance_ready_timeout)
      end

      class InstancePackageError < VagrantMCSError
        error_key(:instance_package_error)
      end

      class InstancePackageTimeout < VagrantMCSError
        error_key(:instance_package_timeout)
      end

      class RsyncError < VagrantMCSError
        error_key(:rsync_error)
      end

      class MkdirError < VagrantMCSError
        error_key(:mkdir_error)
      end

      class ElbDoesNotExistError < VagrantMCSError
        error_key("elb_does_not_exist")
      end
    end
  end
end
