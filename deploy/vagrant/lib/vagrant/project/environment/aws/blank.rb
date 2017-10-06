require "deep_merge"
require "vagrant/project/environment/base"
require 'vagrant/project/mixins/tagging'

module Vagrant
  module Project
    module Environment
      module AWS
        class Blank < Vagrant::Project::Environment::Base
					include Vagrant::Project::Mixins::Tagging

          register :environment, :aws_blank, self.inspect

          def configure_provider(machine, &block)
            machine.provider.set_defaults

            machine.provider.configuration.with{
              ami 'ami-38078c2e'
              tags set_tags(machine.name)
            }

            block.call()
          end

          def configure_provisioner(machine, &block)

          end
        end
      end
    end
  end
end
