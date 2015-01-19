require "vagrant"

module VagrantPlugins
  module MOS
    module Errors
      class VagrantMOSError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_mos.errors")
      end

      class FogError < VagrantMOSError
        error_key(:fog_error)
      end

      class InternalFogError < VagrantMOSError
        error_key(:internal_fog_error)
      end

      class InstanceReadyTimeout < VagrantMOSError
        error_key(:instance_ready_timeout)
      end

      class InstancePackageError < VagrantMOSError
        error_key(:instance_package_error)
      end

      class InstancePackageTimeout < VagrantMOSError
        error_key(:instance_package_timeout)
      end

      class RsyncError < VagrantMOSError
        error_key(:rsync_error)
      end

      class MkdirError < VagrantMOSError
        error_key(:mkdir_error)
      end

      class ElbDoesNotExistError < VagrantMOSError
        error_key("elb_does_not_exist")
      end
    end
  end
end