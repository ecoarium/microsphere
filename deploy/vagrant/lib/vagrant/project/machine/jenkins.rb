require "deep_merge"
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      class Jenkins < Base
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
          attr_config :config
          attr_config :home

          def initialize
            @home = Defaults.home
            @config = {}
            Berkshelf::Berksfile.preposition_berksfile(File.expand_path('jenkins.berks', File.dirname(__FILE__)))
          end

          def configure_this(provisioner)
            artifact_name = $WORKSPACE_SETTINGS[:vagrant][:boxes][:centos][:name]
            artifact_version = $WORKSPACE_SETTINGS[:vagrant][:boxes][:centos][:version]
            provider.box_from_nexus(artifact_name, artifact_version)

            provider.os_name 'centos'
            provider.os_version '6.7'

            provisioner.configure{|chef|
              chef.add_recipe "jenkins_microsphere"

              chef.json[:jenkins]                     = {} if chef.json[:jenkins].nil?

              chef.json[:jenkins_microsphere]         = {} if chef.json[:jenkins_microsphere].nil?
              chef.json[:jenkins_microsphere][:home]  = home

              chef.json.deep_merge!({
                jenkins_microsphere: config
              }) unless config.nil? or config.empty?
            }
          end

        end

        register :machine, :jenkins, self.inspect

        def configuration_class
          Vagrant::Project::Machine::Jenkins::Configuration
        end

        def provisioner_class
          require 'vagrant/project/provisioner/chef'
          Vagrant::Project::Provisioner::Chef
        end

      end
    end
  end
end
