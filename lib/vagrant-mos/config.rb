require "vagrant"

module VagrantPlugins
  module MOS
    class Config < Vagrant.plugin("2", :config)
      # The access key ID for accessing MOS.
      #
      # @return [String]
      attr_accessor :access_key

      # The ID of the template to use.
      #
      # @return [String]
      attr_accessor :template_id

      # The data_disk of the instance to create.
      #
      # @return [String]
      attr_accessor :data_disk

      # The band_width of the instance to create.
      #
      # @return [String]
      attr_accessor :band_width

      # The name of the instance to create.
      #
      # @return [String]
      attr_accessor :name

      # The timeout to wait for an instance to successfully burn into an template.
      #
      # @return [Fixnum]
      attr_accessor :instance_package_timeout

      # The timeout to wait for an instance to become ready.
      #
      # @return [Fixnum]
      attr_accessor :instance_ready_timeout

      # The type of instance to launch, such as "C1_M1"
      #
      # @return [String]
      attr_accessor :instance_type

      # The name of the keypair to use.
      #
      # @return [String]
      attr_accessor :keypair_name

      # The name of the secgroup to use.
      #
      # @return [String]
      attr_accessor :secgroup

      # The name of the zone to use.
      #
      # @return [String]
      attr_accessor :zone

      # The name of the MOS region in which to create the instance.
      #
      # @return [String]
      attr_accessor :region

      # The version of the MOS api to use
      #
      # @return [String]
      attr_accessor :version

      # The secret access key for accessing MOS.
      #
      # @return [String]
      attr_accessor :access_secret

      # The secret access url for accessing MOS.
      #
      # @return [String]
      attr_accessor :access_url

      # Use IAM Instance Role for authentication to MOS instead of an
      # explicit access_id and access_secret
      #
      # @return [Boolean]
      attr_accessor :use_iam_profile

      # Specifies which address to connect to with ssh
      # Must be one of:
      #  - :public_ip_address
      #  - :dns_name
      #  - :private_ip_address
      # This attribute also accepts an array of symbols
      #
      # @return [Symbol]
      attr_accessor :ssh_host_attribute

      def initialize(region_specific=false)
        @access_key                = UNSET_VALUE
        @template_id               = UNSET_VALUE
        @data_disk                 = UNSET_VALUE
        @band_width                = UNSET_VALUE
        @instance_ready_timeout    = UNSET_VALUE
        @instance_package_timeout  = UNSET_VALUE
        @name                      = UNSET_VALUE
        @instance_type             = UNSET_VALUE
        @keypair_name              = UNSET_VALUE
        @secgroup                  = UNSET_VALUE
        @zone                      = UNSET_VALUE
        @region                    = UNSET_VALUE
        @version                   = UNSET_VALUE
        @access_secret             = UNSET_VALUE
        @access_url                = UNSET_VALUE
        @use_iam_profile           = UNSET_VALUE
        @ssh_host_attribute        = UNSET_VALUE

        # Internal state (prefix with __ so they aren't automatically
        # merged)
        @__compiled_region_configs = {}
        @__finalized = false
        @__region_config = {}
        @__region_specific = region_specific
      end

      # Allows region-specific overrides of any of the settings on this
      # configuration object. This allows the user to override things like
      # template_id and keypair name for regions. Example:
      #
      #     mos.region_config "us-east-1" do |region|
      #       region.template_id = "template_id-12345678"
      #       region.keypair_name = "company-east"
      #     end
      #
      # @param [String] region The region name to configure.
      # @param [Hash] attributes Direct attributes to set on the configuration
      #   as a shortcut instead of specifying a full block.
      # @yield [config] Yields a new MOS configuration.
      def region_config(region, attributes=nil, &block)
        # Append the block to the list of region configs for that region.
        # We'll evaluate these upon finalization.
        @__region_config[region] ||= []

        # Append a block that sets attributes if we got one
        if attributes
          attr_block = lambda do |config|
            config.set_options(attributes)
          end

          @__region_config[region] << attr_block
        end

        # Append a block if we got one
        @__region_config[region] << block if block_given?
      end

      #-------------------------------------------------------------------
      # Internal methods.
      #-------------------------------------------------------------------

      def merge(other)
        super.tap do |result|
          # Copy over the region specific flag. "True" is retained if either
          # has it.
          new_region_specific = other.instance_variable_get(:@__region_specific)
          result.instance_variable_set(
          :@__region_specific, new_region_specific || @__region_specific)

          # Go through all the region configs and prepend ours onto
          # theirs.
          new_region_config = other.instance_variable_get(:@__region_config)
          @__region_config.each do |key, value|
            new_region_config[key] ||= []
            new_region_config[key] = value + new_region_config[key]
          end

          # Set it
          result.instance_variable_set(:@__region_config, new_region_config)

        end
      end

      def finalize!
        # Try to get access keys from standard MOS environment variables; they
        # will default to nil if the environment variables are not present.
        @access_key     = ENV['MOS_ACCESS_KEY'] if @access_key     == UNSET_VALUE
        @access_secret  = ENV['MOS_SECRET_KEY'] if @access_secret  == UNSET_VALUE
        @access_url     = ENV['MOS_SECRET_URL'] if @access_url     == UNSET_VALUE

        # Template_id must be nil, since we can't default that
        @template_id = nil if @template_id == UNSET_VALUE

        # Default data_disk
        @data_disk = 0 if @data_disk == UNSET_VALUE

        # Default band_width
        @band_width = 0 if @band_width == UNSET_VALUE

        # Default instance name is nil
        @name = nil if @name == UNSET_VALUE

        # Set the default timeout for waiting for an instance to be ready
        @instance_ready_timeout = 120 if @instance_ready_timeout == UNSET_VALUE

        # Set the default timeout for waiting for an instance to burn into a template
        @instance_package_timeout = 600 if @instance_package_timeout == UNSET_VALUE
        # Default instance type is an C1_M2
        @instance_type = "C1_M2" if @instance_type == UNSET_VALUE
        # Keypair defaults to nil
        @keypair_name = nil if @keypair_name == UNSET_VALUE

        # set default secgroup
        @secgroup = nil if @secgroup == UNSET_VALUE

        # set default zone
        @zone = nil if @zone ==  UNSET_VALUE

        # Default region is us-east-1. This is sensible because MOS
        # generally defaults to this as well.
        @region = "us-east-1" if @region == UNSET_VALUE
        @version = nil if @version == UNSET_VALUE

        # By default we don't use an IAM profile
        @use_iam_profile = false if @use_iam_profile == UNSET_VALUE

        # default to nil
        @ssh_host_attribute = nil if @ssh_host_attribute == UNSET_VALUE

        # Compile our region specific configurations only within
        # NON-REGION-SPECIFIC configurations.
        if !@__region_specific
          @__region_config.each do |region, blocks|
            config = self.class.new(true).merge(self)

            # Execute the configuration for each block
            blocks.each { |b| b.call(config) }

            # The region name of the configuration always equals the
            # region config name:
            config.region = region

            # Finalize the configuration
            config.finalize!

            # Store it for retrieval
            @__compiled_region_configs[region] = config
          end
        end

        # Mark that we finalized
        @__finalized = true
      end

      def validate(machine)
        errors = _detected_errors

        errors << I18n.t("vagrant_mos.config.region_required") if @region.nil?

        if @region
          # Get the configuration for the region we're using and validate only
          # that region.
          config = get_region_config(@region)

          if !config.use_iam_profile
            errors << I18n.t("vagrant_mos.config.access_key_required") if \
              config.access_key.nil?
            errors << I18n.t("vagrant_mos.config.access_secret_required") if \
              config.access_secret.nil?
            errors << I18n.t("vagrant_mos.config.access_url_required") if \
              config.access_url.nil?
          end

          errors << I18n.interpolate("vagrant_mos.config.template_id_required", :region => @region)  if config.template_id.nil?
        end

        { "MOS Provider" => errors }
      end

      # This gets the configuration for a specific region. It shouldn't
      # be called by the general public and is only used internally.
      def get_region_config(name)
        if !@__finalized
          raise "Configuration must be finalized before calling this method."
        end

        # Return the compiled region config
        @__compiled_region_configs[name] || self
      end
    end
  end
end
