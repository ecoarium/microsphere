require "deep_merge"
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      class Nexus < Base
        class Configuration < Vagrant::Project::Machine::Config::Base
          class StorageDisk
            include Vagrant::Project::Mixins::Configurable

            attr_config :device
            attr_config :fstype
            attr_config :size

            def initialize
              @device = '/dev/sdb'
              @fstype = :btrfs
              @size = 250
            end

            def configure_this(provisioner)
              provisioner.configure{|chef|
                chef.json[:nexus_microsphere]                             = {} if chef.json[:nexus_microsphere].nil?
                chef.json[:nexus_microsphere][:storage_disk]              = {} if chef.json[:nexus_microsphere][:storage_disk].nil?
                chef.json[:nexus_microsphere][:storage_disk][:device]     = device
                chef.json[:nexus_microsphere][:storage_disk][:fstype]     = fstype
                chef.json[:nexus_microsphere][:storage_disk][:size]       = size
              }
            end
          end


          include LoggingHelper::LogToTerminal

          attr_config :storage_disk, class: StorageDisk
          attr_config :fqdn

          def initialize
            Berkshelf::Berksfile.preposition_berksfile(File.expand_path('nexus.berks', File.dirname(__FILE__)))
          end

          def configure_this(provisioner)
            artifact_name = $WORKSPACE_SETTINGS[:vagrant][:boxes][:centos][:name]
            artifact_version = $WORKSPACE_SETTINGS[:vagrant][:boxes][:centos][:version]
            provider.box_from_nexus(artifact_name, artifact_version)

            provider.os_name 'centos'
            provider.os_version '6.7'

            provisioner.configure{|chef|

              chef.add_recipe "nexus_microsphere"
              chef.json.deep_merge!({
                nexus: {
                  fqdn: fqdn
                }
              }) unless fqdn.nil?
            }
          end

        end

        register :machine, :nexus, self.inspect

        def configuration_class
          Vagrant::Project::Machine::Nexus::Configuration
        end

        def provisioner_class
          require 'vagrant/project/provisioner/chef'
          Vagrant::Project::Provisioner::Chef
        end

      end
    end
  end
end
