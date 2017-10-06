require "deep_merge"
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      class JenkinsSlaveWindows < Base
        class Configuration < Vagrant::Project::Machine::Config::Base
          class StorageDisk
            include Vagrant::Project::Mixins::Configurable

            attr_config :mount_path
            attr_config :device
            attr_config :fstype
            attr_config :size

            def initialize
              @mount_path = Defaults.home
              @device = '1'
              @fstype = :ntfs
              @size = 120
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
                '/Users/jenkins'
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
            Berkshelf::Berksfile.preposition_berksfile(File.expand_path('jenkins-slave-windows.berks', File.dirname(__FILE__)))
          end

          def configure_this(provisioner)
            artifact_name = $WORKSPACE_SETTINGS[:vagrant][:boxes][:windows][:name]
            artifact_version = $WORKSPACE_SETTINGS[:vagrant][:boxes][:windows][:version]
            provider.box_from_nexus(artifact_name, artifact_version)

            provider.os_name 'windows'
            provider.os_version artifact_name.gsub(/windows|-/,'').upcase

            vagrant_machine.vm.communicator = 'winrm'
            vagrant_machine.vm.guest = :windows
            vagrant_machine.vm.network :forwarded_port, guest: 3389, host: 3389, id: 'rdp', auto_correct: true
            vagrant_machine.winrm.password = 'vagrant'

            provisioner.configure{|chef|

              chef.add_recipe "jenkins_microsphere::slave_windows"
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

        register :machine, :jenkins_slave_windows, self.inspect

        def configuration_class
          Vagrant::Project::Machine::JenkinsSlaveWindows::Configuration
        end

        def provisioner_class
          require 'vagrant/project/provisioner/chef'
          Vagrant::Project::Provisioner::Chef
        end

      end
    end
  end
end
