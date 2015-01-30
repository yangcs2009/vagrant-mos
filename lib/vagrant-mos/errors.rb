require "vagrant"

module VagrantPlugins
  module MOS
    module Errors
      class VagrantMOSError < Vagrant::Errors::VagrantError
        error_namespace("vagrant_mos.errors")
      end

      class MosError < VagrantMOSError
        error_key(:mos_error)
      end

      class InternalMosError < VagrantMOSError
        error_key(:internal_mos_error)
      end

      class InstanceReadyTimeout < VagrantMOSError
        error_key(:instance_ready_timeout)
      end

      class RsyncError < VagrantMOSError
        error_key(:rsync_error)
      end

      class MkdirError < VagrantMOSError
        error_key(:mkdir_error)
      end
    end
  end
end
