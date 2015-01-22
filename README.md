# Vagrant MOS Provider
[![Gitter](https://badges.gitter.im/Join Chat.svg)](https://gitter.im/mitchellh/vagrant-mos?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

<span class="badges">
[![Gem Version](https://badge.fury.io/rb/vagrant-mos.png)][gem]
[![Dependency Status](https://gemnasium.com/mitchellh/vagrant-mos.png)][gemnasium]
</span>

[gem]: https://rubygems.org/gems/vagrant-mos
[gemnasium]: https://gemnasium.com/mitchellh/vagrant-mos

This is a [Vagrant](http://www.vagrantup.com) 1.2+ plugin that adds an [MOS](http://mos.amazon.com)
provider to Vagrant, allowing Vagrant to control and provision machines in
EC2 and VPC.

**NOTE:** This plugin requires Vagrant 1.2+,

## Features

* Boot EC2 or VPC instances.
* SSH into the instances.
* Provision the instances with any built-in Vagrant provisioner.
* Minimal synced folder support via `rsync`.
* Define region-specific configurations so Vagrant can manage machines
  in multiple regions.
* Package running instances into new vagrant-mos friendly boxes

## Usage

Install using standard Vagrant 1.1+ plugin installation methods. After
installing, `vagrant up` and specify the `mos` provider. An example is
shown below.

```
$ vagrant plugin install vagrant-mos
...
$ vagrant up --provider=mos
...
```

Of course prior to doing this, you'll need to obtain an MOS-compatible
box file for Vagrant.

## Quick Start

After installing the plugin (instructions above), the quickest way to get
started is to actually use a dummy MOS box and specify all the details
manually within a `config.vm.provider` block. So first, add the dummy
box using any name you want:

```
$ vagrant box add dummy https://github.com/mitchellh/vagrant-mos/raw/master/mos_box.box
...
```

And then make a Vagrantfile that looks like the following, filling in
your information where necessary.

```
Vagrant.configure("2") do |config|
  config.vm.box = "mos_box"

  config.vm.provider :mos do |mos, override|
    mos.access_key_id = "YOUR KEY"
    mos.secret_access_key = "YOUR SECRET KEY"
    mos.secret_access_url = "YOUR MOS ACCESS URL"
    mos.keypair_name = "KEYPAIR NAME"

    mos.ami = "ami-7747d01e"

    override.ssh.username = "ubuntu"
    override.ssh.private_key_path = "PATH TO YOUR PRIVATE KEY"
  end
end
```

And then run `vagrant up --provider=mos`.

This will start an Ubuntu 12.04 instance in the us-east-1 region within
your account. And assuming your SSH information was filled in properly
within your Vagrantfile, SSH and provisioning will work as well.

Note that normally a lot of this boilerplate is encoded within the box
file, but the box file used for the quick start, the "dummy" box, has
no preconfigured defaults.

If you have issues with SSH connecting, make sure that the instances
are being launched with a security group that allows SSH access.

## Box Format

Every provider in Vagrant must introduce a custom box format. This
provider introduces `mos` boxes. You can view an example box in
the [example_box/ directory](https://github.com/mitchellh/vagrant-mos/tree/master/example_box).
That directory also contains instructions on how to build a box.

The box format is basically just the required `metadata.json` file
along with a `Vagrantfile` that does default settings for the
provider-specific configuration for this provider.

## Configuration

This provider exposes quite a few provider-specific configuration options:

* `access_key_id` - The access key for accessing MOS
* `ami` - The AMI id to boot, such as "ami-12345678"
* `availability_zone` - The availability zone within the region to launch
  the instance. If nil, it will use the default set by Amazon.
* `instance_ready_timeout` - The number of seconds to wait for the instance
  to become "ready" in MOS. Defaults to 120 seconds.
* `instance_package_timeout` - The number of seconds to wait for the instance
  to be burnt into an AMI during packaging. Defaults to 600 seconds.
* `instance_type` - The type of instance, such as "m3.medium". The default
  value of this if not specified is "m3.medium".  "m1.small" has been
  deprecated in "us-east-1" and "m3.medium" is the smallest instance
  type to support both paravirtualization and hvm AMIs
* `keypair_name` - The name of the keypair to use to bootstrap AMIs
   which support it.
* `secret_access_url` - The accee url for accessing MOS
* `private_ip_address` - The private IP address to assign to an instance
  within a [VPC](http://mos.amazon.com/vpc/)
* `region` - The region to start the instance in, such as "us-east-1"
* `secret_access_key` - The secret access key for accessing MOS
* `security_groups` - An array of security groups for the instance. If this
  instance will be launched in VPC, this must be a list of security group
  Name. For a nondefault VPC, you must use security group IDs instead (http://docs.mos.amazon.com/cli/latest/reference/ec2/run-instances.html).
* `iam_instance_profile_arn` - The Amazon resource name (ARN) of the IAM Instance
    Profile to associate with the instance
* `iam_instance_profile_name` - The name of the IAM Instance Profile to associate
  with the instance
* `subnet_id` - The subnet to boot the instance into, for VPC.
* `associate_public_ip` - If true, will associate a public IP address to an instance in a VPC.
* `tags` - A hash of tags to set on the machine.
* `use_iam_profile` - If true, will use [IAM profiles](http://docs.mos.amazon.com/IAM/latest/UserGuide/instance-profiles.html)
  for credentials.
* `block_device_mapping` - Amazon EC2 Block Device Mapping Property

These can be set like typical provider-specific configuration:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :mos do |mos|
    mos.access_key_id = "foo"
    mos.secret_access_key = "bar"
  end
end
```

In addition to the above top-level configs, you can use the `region_config`
method to specify region-specific overrides within your Vagrantfile. Note
that the top-level `region` config must always be specified to choose which
region you want to actually use, however. This looks like this:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :mos do |mos|
    mos.access_key_id = "foo"
    mos.secret_access_key = "bar"
    mos.region = "us-east-1"

    # Simple region config
    mos.region_config "us-east-1", :ami => "ami-12345678"

    # More comprehensive region config
    mos.region_config "us-west-2" do |region|
      region.ami = "ami-87654321"
      region.keypair_name = "company-west"
    end
  end
end
```

The region-specific configurations will override the top-level
configurations when that region is used. They otherwise inherit
the top-level configurations, as you would probably expect.

## Networks

Networking features in the form of `config.vm.network` are not
supported with `vagrant-mos`, currently. If any of these are
specified, Vagrant will emit a warning, but will otherwise boot
the MOS machine.

## Synced Folders

There is minimal support for synced folders. Upon `vagrant up`,
`vagrant reload`, and `vagrant provision`, the MOS provider will use
`rsync` (if available) to uni-directionally sync the folder to
the remote machine over SSH.

See [Vagrant Synced folders: rsync](https://docs.vagrantup.com/v2/synced-folders/rsync.html)


## Other Examples

### Tags

To use tags, simply define a hash of key/value for the tags you want to associate to your instance, like:

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider "mos" do |mos|
    mos.tags = {
	  'Name' => 'Some Name',
	  'Some Key' => 'Some Value'
    }
  end
end
```

### User data

You can specify user data for the instance being booted.

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider "mos" do |mos|
    # Option 1: a single string
    mos.user_data = "#!/bin/bash\necho 'got user data' > /tmp/user_data.log\necho"

    # Option 2: use a file
    mos.user_data = File.read("user_data.txt")
  end
end
```

### Disk size

Need more space on your instance disk? Increase the disk size.

```ruby
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider "mos" do |mos|
    mos.block_device_mapping = [{ 'DeviceName' => '/dev/sda1', 'Ebs.VolumeSize' => 50 }]
  end
end
```

## Development

To work on the `vagrant-mos` plugin, clone this repository out, and use
[Bundler](http://gembundler.com) to get the dependencies:

```
$ bundle
```

Once you have the dependencies, verify the unit tests pass with `rake`:

```
$ bundle exec rake
```

If those pass, you're ready to start developing the plugin. You can test
the plugin without installing it into your Vagrant environment by just
creating a `Vagrantfile` in the top level of this directory (it is gitignored)
and add the following line to your `Vagrantfile` 
```ruby
Vagrant.require_plugin "vagrant-mos"
```
Use bundler to execute Vagrant:
```
$ bundle exec vagrant up --provider=mos
```
