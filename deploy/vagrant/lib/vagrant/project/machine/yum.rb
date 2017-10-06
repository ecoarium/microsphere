require "deep_merge"
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      class Yum < Base
        class Configuration < Vagrant::Project::Machine::Config::Base
          include LoggingHelper::LogToTerminal

          attr_config :config

          def initialize
            Berkshelf::Berksfile.preposition_berksfile(File.expand_path('yum.berks', File.dirname(__FILE__)))
            @config = {
              server: {
                data_bag: 'servers',
                data_bag_item: 'yum'
              },
              repositories: [
                {
                  name: "extras",
                  sync: false,
                  repo_context: "/extras"
                }
              ],
              mirrors: [
              ]
            }
          end

          def configure_this(provisioner)
            artifact_name = $WORKSPACE_SETTINGS[:vagrant][:boxes][:centos][:name]
            artifact_version = $WORKSPACE_SETTINGS[:vagrant][:boxes][:centos][:version]
            provider.box_from_nexus(artifact_name, artifact_version)

            provider.os_name 'centos'
            provider.os_version '6.7'

            provisioner.configure{|chef|

              chef.add_recipe "yum_mirror_microsphere"
              chef.json.deep_merge!({
                yum_mirror: config
              })
            }
          end

        end

        register :machine, :yum, self.inspect

        def configuration_class
          Vagrant::Project::Machine::Yum::Configuration
        end

        def provisioner_class
          require 'vagrant/project/provisioner/chef'
          Vagrant::Project::Provisioner::Chef
        end

      end
    end
  end
end
