require "fog"
require "mos_sdk"
require "log4r"

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

          # Build the fog config
          fog_config = {
              :provider => :mos,
              :region => region
          }
          if region_config.use_iam_profile
            fog_config[:use_iam_profile] = true
          else
            fog_config[:mos_access_key_id] = region_config.access_key_id
            fog_config[:mos_secret_access_key] = region_config.secret_access_key
            fog_config[:mos_secret_url] = region_config.secret_access_url
            #fog_config[:mos_session_token] = region_config.session_token
          end

          fog_config[:endpoint] = region_config.endpoint if region_config.endpoint
          fog_config[:version] = region_config.version if region_config.version

          @logger.info("Connecting to MOS...")
          #env[:mos_compute] = Fog::Compute.new(fog_config)
          env[:mos_compute] = MosSdk::Client.new(region_config.access_key_id, region_config.secret_access_key, region_config.secret_access_url)
          # env[:mos_elb]     = Fog::MOS::ELB.new(fog_config.except(:provider, :endpoint))

          @app.call(env)
        end
      end
    end
  end
end
