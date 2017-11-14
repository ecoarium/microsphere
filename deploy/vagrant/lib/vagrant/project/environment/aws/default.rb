require "deep_merge"
require "vagrant/project/environment/base"
require "vagrant/project/provisioner/chef"
require 'vagrant/project/mixins/tagging'

module Vagrant
  module Project
    module Environment
      module AWS
        class Default < Vagrant::Project::Environment::Base
          include Vagrant::Project::Mixins::Tagging

          register :environment, :aws, self.inspect

          def configure_provider(machine, &block)
            machine.provider.set_defaults

            machine.provider.configuration.with{
              ami 'ami-f3614d96' if ami.nil?

              if subnet_id.nil?
                subnet_id $WORKSPACE_SETTINGS[:aws_resources_report][:aws][:ec2][:subnet].first[:physical_resource_id]
              end

              tags set_tags(machine.name)
            }

            block.call()
          end

          def configure_provisioner(machine, &block)
            return nil unless machine.provisioner_class == Vagrant::Project::Provisioner::Chef
            Berkshelf::Berksfile.preposition_berksfile(File.expand_path('default.berks', File.dirname(__FILE__)))

            machine.provisioner.set_defaults do |chef|
              chef.file_cache_path = '/var/chef/cache/artifacts'

              chef.add_recipe 'chef_commons'
            end

            case machine.vagrant_machine.vm.guest
            when :windows

            else
              machine.provisioner.configure do |chef|
                chef.add_recipe 'timezone-ii'
                chef.add_recipe 'ntp'
              end
            end

            machine.provisioner.configure do |chef|
              block.call()
            end

            machine.provisioner.configure do |chef|
              chef.json.deep_merge!({
                data_bag_secret: 'change-me',
                ec2: {
                  tags: set_tags(machine.name)
                },
                timezone: {
                  use_symlink: false
                },
                tz: 'America/New_York'
              })
            end
          end
        end
      end
    end
  end
end
