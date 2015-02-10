require "mos-sdk"
include MOS

module VagrantPlugins
  module MOS
    class Command < Vagrant.plugin(2, :command)
      def execute
        machine = @env.machine(:default, :mos)
        region = machine.provider_config.region

        # Get the configs
        region_config = machine.provider_config.get_region_config(region)

        @logger.info("Connecting to MOS...")
        mos_compute = Client.new(region_config.access_key, region_config.access_secret, region_config.access_url)
        results = mos_compute.describe_instance_types["InstanceType"]
        puts results
        0
      end


    end
  end
end
