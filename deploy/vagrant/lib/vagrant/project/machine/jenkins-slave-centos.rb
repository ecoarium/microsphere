require "deep_merge"
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      class JenkinsSlaveCentos < Base
        class Configuration < Vagrant::Project::Machine::Config::Base
          class StorageDisk
            include Vagrant::Project::Mixins::Configurable

            attr_config :mount_path
            attr_config :device
            attr_config :fstype
            attr_config :size

            def initialize
              @mount_path = Defaults.home
              @device = '/dev/sdb'
              @fstype = :btrfs
              @size = 250
            end

            def configure_this(provisioner)
              provisioner.configure{|chef|
                chef.json[:jenkins_microsphere]                             = {} if chef.json[:jenkins_microsphere].nil?
                chef.json[:jenkins_microsphere][:storage_disk]              = {} if chef.json[:jenkins_microsphere][:storage_disk].nil?
                chef.json[:jenkins_microsphere][:storage_disk][:mount_path] = mount_path
                chef.json[:jenkins_microsphere][:storage_disk][:device]     = device
                chef.json[:jenkins_microsphere][:storage_disk][:fstype]     = fstype
                chef.json[:jenkins_microsphere][:storage_disk][:size]       = size
              }
            end
          end

          class Defaults
            class << self
              def home
                '/var/lib/jenkins'
              end
            end
          end


          include LoggingHelper::LogToTerminal
          attr_config :storage_disk, class: StorageDisk

          attr_config :customization_recipes, is_array: true
          attr_config :labels, is_array: true
          attr_config :executors
          attr_config :usage_mode
          attr_config :master_endpoint
          attr_config :config
          attr_config :home
          attr_config :os_version

          attr_config :name do
            if name.nil? or name.empty?
              {
                is_valid: false,
                failure_message: "
the name of the slave must be set
"
              }
            else
              {is_valid: true}
            end
          end

          def initialize
            @home = Defaults.home
            @executors   = 5
            @usage_mode  = 'exclusive'

            jenkins_master = get_data_bag_item('servers', 'jenkins')
            @master_endpoint = "https://#{jenkins_master[:fqdn]}"

            @config = {}
            Berkshelf::Berksfile.preposition_berksfile(File.expand_path('jenkins-slave-centos.berks', File.dirname(__FILE__)))
          end

          def configure_this(provisioner)

            case os_version
            when '6.0'
              os_version = '6.0'
              artifact_name = "centos-6-0-x86_64"
              artifact_version = "1.0.10.next"
            else
              os_version = '6.7'
              artifact_name = "centos-6-7-x86_64"
              artifact_version = "1.0.5.next"
            end

            provider.box_from_nexus(artifact_name, artifact_version)

            provider.os_name 'centos'
            provider.os_version os_version

            provisioner.configure{|chef|

              chef.add_recipe "jenkins_microsphere::slave_centos"

              chef.json[:jenkins]                     = {} if chef.json[:jenkins].nil?
              chef.json[:jenkins][:master]            = {} if chef.json[:jenkins][:master].nil?
              chef.json[:jenkins][:master][:endpoint] = master_endpoint


              chef.json[:jenkins_microsphere]         = {} if chef.json[:jenkins_microsphere].nil?
              chef.json[:jenkins_microsphere][:home]  = home

              chef.json[:jenkins_microsphere][:slave]         = {} if chef.json[:jenkins_microsphere][:slave].nil?
              chef.json[:jenkins_microsphere][:slave][:name]  = name

              chef.json[:jenkins_microsphere][:customization]                       = {} if chef.json[:jenkins_microsphere][:customization].nil?
              chef.json[:jenkins_microsphere][:customization][:slave]               = {} if chef.json[:jenkins_microsphere][:customization][:slave].nil?
              chef.json[:jenkins_microsphere][:customization][:slave][:recipes]     = customization_recipes
              chef.json[:jenkins_microsphere][:customization][:slave][:labels]      = labels
              chef.json[:jenkins_microsphere][:customization][:slave][:executors]   = executors
              chef.json[:jenkins_microsphere][:customization][:slave][:usage_mode]  = usage_mode

              chef.json.deep_merge!({
                jenkins_microsphere: config
              }) unless config.nil? or config.empty?
            }
          end

        end

        register :machine, :jenkins_slave_centos, self.inspect

        def configuration_class
          Vagrant::Project::Machine::JenkinsSlaveCentos::Configuration
        end

        def provisioner_class
          require 'vagrant/project/provisioner/chef'
          Vagrant::Project::Provisioner::Chef
        end

      end
    end
  end
end
