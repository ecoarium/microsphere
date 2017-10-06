require 'shell-helper'
require 'logging-helper'
require 'fileutils'
require 'digest/md5'
require 'tmpdir'
require 'curl'
require 'json'
require 'pp'

module Packer
  class BaselineCreator

    include ShellHelper::Shell
    include LoggingHelper::LogToTerminal

    attr_reader :unprocessed_template_file_path, :processed_template_file_path
    attr_reader :variables_file_path, :build_directory

    def initialize()
      $WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:virtualbox] = {}
      $WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:virtualbox][:box] = {}

      @build_directory = "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path]}/.build"

      FileUtils.mkdir_p(@build_directory) unless File.exist?(@build_directory)

      @unprocessed_template_file_path = "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path]}/template.json"
      @variables_file_path = "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path]}/variables.rb"
      @processed_template_file_path = "#{build_directory}/template.json"
    end

    def process_template
      if variables_file_exist?
        create_variables_file_content

        debug "variables -> #{get_existing_variables_file_checksum} : #{hash_of_template_variables} <- template"

        if get_existing_variables_file_checksum != hash_of_template_variables
          fail_and_show_content_for_new_variables_file
        end
      else
        create_initial_variables_file
      end

      load_template
    end

    def build(packer_opts)
      ENV['PACKER_CACHE_DIR'] = "#{build_directory}/packer_cache"
      debug_packer = ''
      debug_packer = '-debug' if ENV['LOG_LEVEL'].upcase.include?('DEBUG')

      shell_command!(
        "packer build -force #{packer_opts} #{debug_packer} #{processed_template_file_path}",
        cwd: $WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path],
        timeout: 7200
      )
    end

    def variables_file_exist?
      File.exist?(variables_file_path)
    end

    def get_existing_variables_file_checksum
      get_it = false
      File.open(variables_file_path, "r").each{|line|
        if get_it
          debug "raw line with checksum from variables file(#{variables_file_path}) in single quotes:
'#{line}'"
          checksum = line.chomp[/#\s+\[(\w+)\]/, 1]
          raise "could not extract the checksum from the variables file line in single quotes:
'#{line}'
" if checksum.nil?
          return checksum
        end

        get_it = true if line.chomp == begin_generated_content_banner
      }
      raise "could not find existing checksum in variables file: #{variables_file_path}"
    end

    def begin_generated_content_banner
      '####################### BEGIN GENERATED CONTENT DONT CHANGE #######################'
    end

    def end_generated_content_banner
      '######################## END GENERATED CONTENT DONT CHANGE ########################'
    end

    def create_variables_file_content
      local_var_hash_of_template_variables = hash_of_template_variables

      config_source_buffer = StringIO.new

      NilClass.class_eval("
        def to_s
          'null'
        end
      ")

      config_source_buffer.puts "
#{begin_generated_content_banner}
# [#{local_var_hash_of_template_variables}]
#{end_generated_content_banner}

# Any string value of 'null' below must be set to a new value.

#{unprocessed_template[:variables].join(" '", "'\n")}'
"
      NilClass.class_eval("
        def to_s
          ''
        end
      ")

      config_source = config_source_buffer.string
    end

    def create_initial_variables_file
      File.open(variables_file_path, 'w') { |file|
        file.write(create_variables_file_content)
      }

      raise "the variables for the packer template file did not exist, one was created that will require you to edit it
  this file will set all the variable values in the packer template that would normally be passed at the command line
  https://www.packer.io/docs/templates/user-variables.html

  for example ->

  a portion of a template file showing the variables:

  |    }
  |      ...
  |      \"variables\": {
  |        \"duck\": \"false\",
  |        \"bird\": \"true\",
  |        \"bunny\": null,
  |        \"dog\": null
  |      }
  |    }

  the variables file would look like:

  |####################### BEGIN GENERATED CONTENT DONT CHANGE #######################
  |# [0b8155d8147119c35e2d15716f1c895f]
  |######################## END GENERATED CONTENT DONT CHANGE ########################
  |
  |# Any string value of 'null' below must be set to a new value.
  |
  |duck 'false'
  |bird 'true'
  |bunny 'null'
  |dog 'null'


  please find it here:
  #{variables_file_path}
  "
    end

    def fail_and_show_content_for_new_variables_file
      raise "the variables file for the packer template are out of date
the variables in the template file have changed
please update the existing variables file:
#{variables_file_path}

below is the generated content of what an initial file would look like
please merge the content with your existing file:

#{create_variables_file_content}


"
    end

    def unprocessed_template
      return @unprocessed_template unless @unprocessed_template.nil?
      @unprocessed_template = JSON.parse(IO.read(unprocessed_template_file_path), :symbolize_names => true)
    end

    def hash_of_template_variables
      flattened_variables = unprocessed_template[:variables].join("'='", "'\n'")
      hash = Digest::MD5.hexdigest(flattened_variables)
    end

    def load_template
      class_source_buffer = StringIO.new

      NilClass.class_eval("
        def to_s
          'null'
        end
      ")

      class_source_buffer.puts "

  class Packer
    class Variables
      include LoggingHelper::LogToTerminal

      attr_reader :build_directory

      def initialize(build_directory)
        @build_directory = build_directory
        @#{unprocessed_template[:variables].join(" = '", "'\n      @")}'
      end
  "

      NilClass.class_eval("
        def to_s
          ''
        end
      ")


      unprocessed_template[:variables].keys.each{|key|
        class_source_buffer.puts "
      def #{key}(value=nil)
        if !value.nil? and value != ''
          @#{key} = value
        end
        @#{key}
      end
  "
      }

      class_source_buffer.puts "
      def config(file_path)
        self.instance_eval(File.read(file_path), file_path, 1)
      end

    end
  end

  "
      class_source = class_source_buffer.string

      eval class_source

      packer_variables = Packer::Variables.new(build_directory)

      packer_variables.config(variables_file_path)

      packer_variables.instance_eval("

      def create_template(new_template_file_path, template)
        template[:variables].keys.each{|key|
          value = instance_variable_get(\"@\#{key}\".to_s)
          raise \"the template variable \#{key} has a nil value!\" if value.nil?
          template[:variables][key] = value
        }

        File.open(new_template_file_path, 'w'){|file|
          file.write(JSON.pretty_generate template)
        }
      end

  ")

      packer_variables.create_template(processed_template_file_path, unprocessed_template)
    end


  end
end
