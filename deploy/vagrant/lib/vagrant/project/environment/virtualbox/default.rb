require "deep_merge"
require "vagrant/project/environment/base"

module Vagrant
  module Project
    module Environment
      module Virtualbox
        class Default < Vagrant::Project::Environment::Base
          register :environment, :virtualbox, self.inspect

          def configure_provider(machine, &block)
            machine.provider.set_defaults{|vbox|
              #example
              #vbox.name = vagrant_machine.name
            }

            file_cache = "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:vagrant][:home]}/#{$WORKSPACE_SETTINGS[:vagrant][:default][:provider]}/.filecache"

            machine.provider.configuration.with(file_cache){|file_cache|
              case machine.vagrant_machine.vm.guest
              when :windows

              when :darwin

              else
                synced_folders{
                  host_path  "#{file_cache}/yum_cache"
                  guest_path '/var/cache/yum'
                  create true
                }
                synced_folders{
                  host_path  "#{file_cache}/yum_repo"
                  guest_path '/var/yum_repo'
                  create true
                }
                synced_folders{
                  host_path  "#{file_cache}/chef_gems"
                  guest_path '/opt/chef/embedded/lib/ruby/gems/2.1.0/cache'
                  create true
                }
                synced_folders{
                  host_path  "#{file_cache}/chef"
                  guest_path '/var/chef/cache/artifacts'
                  create true
                }
              end
            }

            block.call()

          end

          def configure_provisioner(machine, &block)
            Berkshelf::Berksfile.preposition_berksfile(File.expand_path('virtualbox_default.berks', File.dirname(__FILE__)))

            machine.provisioner.set_defaults do |chef|
              chef.file_cache_path = '/var/chef/cache/artifacts'

              chef.add_recipe "chef_commons"
            end

            case machine.vagrant_machine.vm.guest
            when :windows
              machine.provisioner.configure do |chef|
                chef.add_recipe "dev_commons::activate_windows"
                chef.add_recipe "dev_commons::hosts"
              end
            when :darwin

            else
              machine.provisioner.configure do |chef|
                chef.add_recipe "dev_commons::hosts"
                chef.add_recipe "yum_mirror::repo"
                chef.add_recipe "yum"
                chef.add_recipe "timezone-ii"
                chef.add_recipe "ntp"
              end
            end

            machine.provisioner.configure do |chef|
              block.call()
            end

            machine.provisioner.configure do |chef|
              if ARGV.include?('machines')
              chef.json.deep_merge!({
                  ec2: {
                    mock: {
                      in_ec2?: false
                    }
                  }
                })
              end

              chef.json.deep_merge!({
                data_bag_secret: 'change-me',
                yum: {
                  main: {
                    keepcache: true
                  }
                },
                yum_mirror: {
                  mirrors: [
                    {
                      name: "#{$WORKSPACE_SETTINGS[:company][:name]}-rhel-6-extras",
                      url:  "https://yum.#{$WORKSPACE_SETTINGS[:domain_name]}/extras"
                    }
                  ],
                  favor: true
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
