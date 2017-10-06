require "deep_merge"
require "vagrant/project/machine/base"
require "vagrant/project/machine/config/base"
require "vagrant/project/mixins/configurable"
require 'logging-helper'

module Vagrant
  module Project
    module Machine
      class Blank < Base
        class Configuration < Vagrant::Project::Machine::Config::Base
          include LoggingHelper::LogToTerminal

          def initialize
            
          end

          def configure_this(provisioner)

          end

        end

        register :machine, :blank, self.inspect

        def configuration_class
          Vagrant::Project::Machine::Blank::Configuration
        end

        def provisioner_class
          require 'vagrant/project/provisioner/none'
          Vagrant::Project::Provisioner::None
        end

      end
    end
  end
end
