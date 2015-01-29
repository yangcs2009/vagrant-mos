require "log4r"
require "mos-sdk"
include MOS

module VagrantPlugins
  module MOS
    module Action
      # This action connects to MOS, verifies credentials work, and
      # puts the MOS connection object into the `:mos_compute` key
      # in the environment.
      class ConnectMOS
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant_mos::action::connect_mos")
        end

        def call(env)
          # Get the region we're going to booting up in
          region = env[:machine].provider_config.region

          # Get the configs
          region_config = env[:machine].provider_config.get_region_config(region)

          @logger.info("Connecting to MOS...")
          env[:mos_compute] = Client.new(region_config.access_key_id, region_config.secret_access_key, region_config.secret_access_url)

          @app.call(env)
        end
      end
    end
  end
end
