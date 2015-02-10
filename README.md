# Vagrant MOS Provider

<span class="badges">
[![Gem Version](https://badge.fury.io/rb/vagrant-mos.png)][gem]
[![Dependency Status](https://gemnasium.com/mitchellh/vagrant-mos.png)][gemnasium]
</span>

[gem]: https://rubygems.org/gems/vagrant-mos
[gemnasium]: https://gemnasium.com/mitchellh/vagrant-mos

该版本的[Vagrant](http://www.vagrantup.com) 1.2+ plugin现在支持[MOS](http://cloud.sankuai.com/)
provider，从而使得Vagrant可以像管理VirtualBox那样管理美团云主机。

**NOTE:** 该版本的plugin要求Vagrant版本为 1.2+,而且最好是最新版本

## 主要功能

* 支持Vagrant常用命令 `up`, `status`, `destroy`, `halt`, `reload`, `package`, `ssh`以及`mos-templates` 
* 创建 MOS 主机实例
* SSH连接已创建的主机
* 支持通过`rsync`命令同步文件夹
* 通过`vagrant status`命令管理已创建的MOS主机
* 通过`vagrant package`命令创建MOS实例模板
* 通过`vagrant mos-templates`查看可使用的模板
  
## 安装使用

按照安装Vagrant 1.2+ plugin的标准步骤安装即可。**在完成plugin以及MOS box安装后**，通过`vagrant up` 即可创建Vagrant MOS主机实例。下面是样例。

```
$ vagrant plugin install vagrant-mos
...
$ vagrant up --provider=mos
...
```

## 快速入门

在按照上述步骤完成vagrant plugin安装后，要想快速使用vagrant MOS创建主机，首先要有MOS box。用户可以执行下面的命令安装MOS box。

```
$ vagrant box add mos_box https://github.com/yangcs2009/vagrant-mos/raw/master/mos.box
...
```

完成以上工作后，就可以开始创建MOS主机了，首先创建一个工作目录，然后创建一份Vagrant配置文档。

```
$ mkdir vagrant_workplace
$ cd vagrant_workplace
$ vagrant init
```
然后就会发现在该目录下新生成一个Vagrantfile文档，编辑该文档如下：

```
Vagrant.configure("2") do |config|
  config.vm.box = "mos_box"

  config.vm.provider :mos do |mos, override|
    mos.access_key = "YOUR KEY"
    mos.access_secret = "YOUR SECRET KEY"
    mos.access_url = "YOUR MOS ACCESS URL"
    mos.keypair_name = "KEYPAIR NAME"
    mos.template_id = "fa1026fe-c082-4ead-8458-802bf65ca64c"
    mos.data_disk = 100
    mos.band_with = 10
    override.ssh.username = "root"
    override.ssh.private_key_path = "PATH TO YOUR PRIVATE KEY"
  end
end
```

完成后保存，然后执行 `vagrant up --provider=mos`就可以创建MOS主机了。

当然这一切都是假定你的ssh配置信息已经完成，如何设置ssh信息请参见[美团云秘钥](http://cloud.sankuai.com/console/#keypairs)。

## Box设置

不同的vagrant provider都必须使用符合响应要求的box来创建新主机。我们样例采用的是MOS的box `mos`。用户可以查看[example_box](https://github.com/yangcs2009/vagrant-mos/tree/master/example_box)，从中还可以学习如何设置自己的boxes。


## 配置文档

MOS provider设置了若干参数，主要参数说明如下：

* `access_key` - 访问美团云的key
* `access_secret` - 访问美团云的secret
* `access_url` -访问美团云的url
* `region` - 创建主机的region，例如 "beijing"
* `template_id` - 创建美团云主机的镜像ID，例如 "fa1026fe-c082-4ead-8458-802bf65ca64c"，用户可以使用`vagrant mos-templates`查看可以使用的镜像  
* `data_disk` - 创建美团云主机的数据盘大小，单位为GB，例如100代表创建100G的数据盘  
* `band_width` - 创建美团云主机的外网带宽大小，单位为Mbps，例如10代表选择10Mbps的外网带宽
* `instance_ready_timeout` - 等待MOS主机创建成功最长时间，单位为秒。默认为120s
* `instance_package_timeout` - 等待模板创建成功最长时间，单位为秒。默认为600s
* `instance_name` - 创建的MOS主机名称，例如 "ubuntu007"。
* `instance_type` - 创建的MOS主机类型，例如"C1_M1". 默认配置为 "C1_M2"默认配置为 "C1_M2"代表1核CPU，2G内存，以此类推，用户可以使用`vagrant mos-flavors`查看
* `keypair_name` - 用户使用的秘钥名称。通过使用秘钥，用户登录该创建的主机时就不需要在输入繁琐的密码。具体操作用户可登陆**[美团云秘钥](http://cloud.sankuai.com/console/#keypairs)**查看。
* `use_iam_profile` - 如果该参数设置，则使用[IAM profiles](http://docs.mos.amazon.com/IAM/latest/UserGuide/instance-profiles.html)认证。

一个典型的配置文档如下所示：

```  
Vagrant.configure("2") do |config|
  # ... other stuff

  config.vm.provider :mos do |mos|
    mos.access_key = "your_key"
    mos.access_secret = "your_secret"
    mos.access_url = "your_access_urll"
  end
end
```

## 网络

MOS的网络功能 `config.vm.network` 暂时不支持。如果用户指定相关参数的话，vagrant会给出警告。

## 文件夹同步

MOS 支持文件夹同步。通过使用`rsync` 命令来指定。

具体内容可以参见 [Vagrant Synced folders: rsync](https://docs.vagrantup.com/v2/synced-folders/rsync.html)


## 自定义开发

如果用户需要在 `vagrant-mos` plugin基础上实现自己的功能，克隆该工程，然后使用
[Bundler](http://gembundler.com)获得依赖：

```
$ bundle
```

完成后，使用`rake`测试:

```
$ bundle exec rake
```

如果以上步骤没有问题的话，用户就可以开始自己的开发工作了。