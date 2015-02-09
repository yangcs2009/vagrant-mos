require "vagrant-mos/config"

describe VagrantPlugins::MOS::Config do
  let(:instance) { described_class.new }

  # Ensure tests are not affected by MOS credential environment variables
  before :each do
    ENV.stub(:[] => nil)
  end

  describe "defaults" do
    subject do
      instance.tap do |o|
        o.finalize!
      end
    end

    its("access_key")     { should be_nil }
    its("template_id")               { should be_nil }
    its("instance_ready_timeout") { should == 120 }
    its("instance_package_timeout") { should == 600 }
    its("name")     { should be_nil }
    its("instance_type")     { should == "C1_M2" }
    its("keypair_name")      { should be_nil }
    its("region")            { should == "us-east-1" }
    its("access_secret") { should be_nil }
    its("access_url") { should be_nil }
    its("use_iam_profile")   { should be_false }
    its("ssh_host_attribute") { should be_nil }
  end

  describe "overriding defaults" do
    # I typically don't meta-program in tests, but this is a very
    # simple boilerplate test, so I cut corners here. It just sets
    # each of these attributes to "foo" in isolation, and reads the value
    # and asserts the proper result comes back out.
    [:access_key, :template_id, :data_disk, :band_width, :instance_ready_timeout, :name,
     :instance_package_timeout, :instance_type, :keypair_name, :ssh_host_attribute,
      :region, :access_secret, :access_url,
      :use_iam_profile].each do |attribute|

      it "should not default #{attribute} if overridden" do
        instance.send("#{attribute}=".to_sym, "foo")
        instance.finalize!
        instance.send(attribute).should == "foo"
      end
    end

  end

  describe "getting credentials from environment" do
    context "without EC2 credential environment variables" do
      subject do
        instance.tap do |o|
          o.finalize!
        end
      end

      its("access_key")     { should be_nil }
      its("access_secret") { should be_nil }
      its("access_url")     { should be_nil }
    end

    context "with MOS credential environment variables" do
      before :each do
        ENV.stub(:[]).with("MOS_ACCESS_KEY").and_return("access_key")
        ENV.stub(:[]).with("MOS_SECRET_KEY").and_return("secret_key")
        ENV.stub(:[]).with("MOS_SECRET_URL").and_return("secret_url")
      end

      subject do
        instance.tap do |o|
          o.finalize!
        end
      end

      its("access_key")     { should == "access_key" }
      its("access_secret") { should == "secret_key" }
      its("access_url")     { should == "secret_url" }
    end
  end

  describe "region config" do
    let(:config_access_key)     { "foo" }
    let(:config_template_id)               { "foo" }
    let(:config_instance_type)     { "foo" }
    let(:config_name)     { "foo" }
    let(:config_keypair_name)      { "foo" }
    let(:config_region)            { "foo" }
    let(:config_access_secret) { "foo" }
    let(:config_access_url)     { "foo" }

    def set_test_values(instance)
      instance.access_key     = config_access_key
      instance.template_id               = config_template_id
      instance.instance_type     = config_instance_type
      instance.name     = config_name
      instance.keypair_name      = config_keypair_name
      instance.region            = config_region
      instance.access_secret = config_access_secret
      instance.access_url     = config_access_url
    end

    it "should raise an exception if not finalized" do
      expect { instance.get_region_config("us-east-1") }.
        to raise_error
    end

    context "with no specific config set" do
      subject do
        # Set the values on the top-level object
        set_test_values(instance)

        # Finalize so we can get the region config
        instance.finalize!

        # Get a lower level region
        instance.get_region_config("us-east-1")
      end

      its("access_key")     { should == config_access_key }
      its("template_id")               { should == config_template_id }
      its("instance_type")     { should == config_instance_type }
      its("name")     { should == config_name }
      its("keypair_name")      { should == config_keypair_name }
      its("region")            { should == config_region }
      its("access_secret") { should == config_access_secret }
      its("access_url") { should == config_access_url }
    end

    context "with a specific config set" do
      let(:region_name) { "hashi-region" }

      subject do
        # Set the values on a specific region
        instance.region_config region_name do |config|
          set_test_values(config)
        end

        # Finalize so we can get the region config
        instance.finalize!

        # Get the region
        instance.get_region_config(region_name)
      end

      its("access_key")     { should == config_access_key }
      its("template_id")               { should == config_template_id }
      its("instance_type")     { should == config_instance_type }
      its("name")     { should == config_name }
      its("keypair_name")      { should == config_keypair_name }
      its("region")            { should == region_name }
      its("access_secret") { should == config_access_secret }
      its("access_url") { should == config_access_url }
    end

    describe "inheritance of parent config" do
      let(:region_name) { "hashi-region" }

      subject do
        # Set the values on a specific region
        instance.region_config region_name do |config|
          config.template_id = "child"
        end

        # Set some top-level values
        instance.access_key = "parent"
        instance.template_id = "parent"

        # Finalize and get the region
        instance.finalize!
        instance.get_region_config(region_name)
      end

      its("access_key") { should == "parent" }
      its("template_id")           { should == "child" }
    end

    describe "shortcut configuration" do
      subject do
        # Use the shortcut configuration to set some values
        instance.region_config "us-east-1", :template_id => "child"
        instance.finalize!
        instance.get_region_config("us-east-1")
      end

      its("template_id") { should == "child" }
    end

    describe "merging" do
      let(:first)  { described_class.new }
      let(:second) { described_class.new }
    end
  end
end
