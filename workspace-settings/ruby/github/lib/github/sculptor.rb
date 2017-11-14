require 'fileutils'
require 'logging-helper'
require 'tempfile'
require 'tmpdir'
require 'facets/string'
require 'pp'

module Github
  class Sculptor
    include LoggingHelper::LogToTerminal

    attr_reader :replace_file_path, :mud_repo_name, :mud_repo_url
    attr_reader :ecosystem_domain_name, :project_parent_name, :project_name, :project_git_repo_url
    attr_reader :temp_dir, :mud_repo_temp_path, :project_repo_temp_path
    attr_reader :token_value_pairs

    def initialize(mud_repo_name, mud_repo_url, ecosystem_domain_name, project_parent_name, project_name, project_git_repo_url, token_value_pairs={})
      @replace_file_path = File.expand_path('replace.rb', File.dirname(__FILE__))

      @ecosystem_domain_name = ecosystem_domain_name
      @project_parent_name = project_parent_name
      @project_name = project_name
      @project_git_repo_url = project_git_repo_url
      @mud_repo_name = mud_repo_name
      @mud_repo_url = mud_repo_url
      @token_value_pairs = {}

      token_id = 'TKN'
      delimiter = '-.-'
      [
        "TKN-.-ecosystem_domain_name-.-TKN",
        "TKN-.-project_git_repo_url-.-TKN",

        "TKN-.-project_name-.-TKN",
        "TKN-.-project_parent_name-.-TKN",

        "TKN-.-project_name_dot_delimited-.-TKN",
        "TKN-.-project_parent_name_dot_delimited-.-TKN",

        "TKN-.-camel_case_project_name-.-TKN",
        "TKN-.-camel_case_project_parent_name-.-TKN",

        "TKN-.-snake_case_project_name-.-TKN",
        "TKN-.-snake_case_project_parent_name-.-TKN",

        "TKN-.-snake_camel_case_project_name-.-TKN",
        "TKN-.-snake_camel_case_project_parent_name-.-TKN"
      ].each{|token_name|
        @token_value_pairs["#{token_id}#{delimiter}#{token_name}#{delimiter}#{token_id}"] = nil
      }
      @token_value_pairs.merge(token_value_pairs)
    end

    def populate_repo
      Dir.mktmpdir{|temp_dir|
        @temp_dir = temp_dir
        @mud_repo_temp_path = File.expand_path(mud_repo_name, temp_dir)
        @project_repo_temp_path = File.expand_path(project_name, temp_dir)
        Dir.chdir(temp_dir) do
          clone_mud_repo

          FileUtils.rm_rf("#{mud_repo_temp_path}/.git")
          replace_tokens

          clone_new_project_repo
          FileUtils.cp_r("#{mud_repo_temp_path}/.", project_name)

          push_to_new_project_repo
        end
      }
    end

    def clone_mud_repo
      git_clone(mud_repo_url)
    end

    def clone_new_project_repo
      git_clone(project_git_repo_url)
    end

    def push_to_new_project_repo
      Dir.chdir(project_name){
        shell_out! 'git add .'
        shell_out! 'git commit -a -m "initial commit"'
        shell_out! 'git push origin master'
        shell_out! 'git checkout -b next'
        shell_out! 'git push origin next'
      }
    end

    def git_clone(repo_url)
      shell_out! "git clone #{repo_url}"
    end

    def replace_tokens()
      process_token_value_pairs
      rename_paths(mud_repo_temp_path, token_value_pairs)
      replace_in_files(mud_repo_temp_path, token_value_pairs)
    end

    def process_token_value_pairs
      snake_case_project_name = project_name.snakecase
      snake_case_project_parent_name = project_parent_name.gsub(/\//, '_').snakecase

      project_name_dot_delimited = snake_case_project_name.gsub(/_/, '.')
      project_parent_name_dot_delimited = snake_case_project_parent_name.gsub(/_/, '.')

      camel_case_project_name = snake_case_project_name.camelcase(:upper)
      camel_case_project_parent_name = snake_case_project_parent_name.camelcase(:upper)

      snake_camel_case_project_name = snake_case_project_name.split('_').collect{|word| word.uppercase}.join('_')
      snake_camel_case_project_parent_name = snake_case_project_parent_name.split('_').collect{|word| word.uppercase}.join('_')
      
      @token_value_pairs = {
        "TKN-.-ecosystem_domain_name-.-TKN" => ecosystem_domain_name,
        "TKN-.-project_git_repo_url-.-TKN" => project_git_repo_url,

        "TKN-.-project_name-.-TKN" => project_name,
        "TKN-.-project_parent_name-.-TKN" => project_parent_name,

        "TKN-.-project_name_dot_delimited-.-TKN" => project_name_dot_delimited,
        "TKN-.-project_parent_name_dot_delimited-.-TKN" => project_parent_name_dot_delimited,

        "TKN-.-camel_case_project_name-.-TKN" => camel_case_project_name,
        "TKN-.-camel_case_project_parent_name-.-TKN" => camel_case_project_parent_name,

        "TKN-.-snake_case_project_name-.-TKN" => snake_case_project_name,
        "TKN-.-snake_case_project_parent_name-.-TKN" => snake_case_project_parent_name,

        "TKN-.-snake_camel_case_project_name-.-TKN" => snake_camel_case_project_name,
        "TKN-.-snake_camel_case_project_parent_name-.-TKN" => snake_camel_case_project_parent_name
      }.merge(token_value_pairs)
    end

    def rename_paths(location, substitutions)
      Dir.chdir(location) do
        substitutions.each{ |token,value|
          glob = "**/*#{Regexp.escape(token)}*"
          
          #while Dir.glob(glob).size != 0
          Dir.glob(glob) do |partial_source_path|
            warn "
replacing token #{token} with value #{value} in paths:"
              
            #partial_source_path = Dir.glob(glob).first

            source_path = File.expand_path(partial_source_path, location)

            raise "somehow the source_path '#{source_path}' does not exist" unless File.exist? source_path

            target_path = File.expand_path(partial_source_path.gsub(/#{Regexp.escape(token)}/, value), location)
            begin
              warn "FileUtils.move(#{source_path}, #{target_path})"

              FileUtils.move(source_path, target_path)
              debug "
renamed path:
source_path -> #{source_path}
target_path -> #{target_path}

"
            rescue Exception => e
              fail %/
error moving file:
source: #{source_path}
target: #{target_path}

#{e.message}
#{e.backtrace.join("\n")}
/
            end
          end
        }
      end
    end

    def get_matching_file_list(location, token, value)
      grep_command_line = "GLOBIGNORE=.:..; egrep -Irn '#{token}' . 2>/dev/null | grep -v '\\.git\/'"

      grep_output = nil
      Dir.chdir(location) do
        debug "
executing: [#{grep_command_line}] in: [#{location}]
"
        grep_output = `#{grep_command_line}`
      end

      fail "grep failed (exitstatus #{$?.exitstatus}):\n#{grep_command_line}" if $?.exitstatus != 0 and !grep_output.empty?

      warn "
replacing token #{token} with value #{value} in files:"

      seen = []

      grep_output.split("\n").collect{|grep_line|
        path = File.expand_path(grep_line.split(':')[0], location)

        unless seen.include?(path)
          seen << path
        end

        path
      }.uniq.compact
    end

    def tmp_repo_dir
      return @tmp_repo_dir unless @tmp_repo_dir.nil?
      @tmp_repo_dir = "#{temp_dir}/tmp_repo_dir"
      FileUtils.mkdir @tmp_repo_dir unless File.exist?(@tmp_repo_dir)
      @tmp_repo_dir
    end

    def make_temp_file(file_path)
      temp_file_path = file_path.gsub(/#{Regexp.escape(mud_repo_temp_path)}/, tmp_repo_dir)
      FileUtils.mkdir_p File.dirname(temp_file_path) unless File.exist?(File.dirname(temp_file_path))

      debug"
      make_temp_file
        original file: #{file_path}
        temp_file:     #{temp_file_path}
"

      File.open(temp_file_path, 'w')
    end

    def search_file_replace(file_path, regex, replace)
      exp = Regexp.new(regex)

      temp_file = make_temp_file(file_path)
      
      File.readlines(file_path).each do |line|
        debug "#{line}.match(#{exp.inspect})"
        if line.match(exp)
          debug "

    temp_file.write #{line}.gsub!(#{exp}, #{replace})

    from:
    #{line}

    to:
    #{line.gsub(exp, replace)}

    "
          temp_file.write line.gsub!(exp, replace)
        else
          temp_file.write line
        end
      end

      temp_file.close
      FileUtils.move(temp_file, file_path, force: true)
    end

    def replace_in_file(file, substitutions)
      substitutions.each{ |token,value|
        begin
          search_file_replace(file, token, value)
        rescue Exception => e
          fail %/
      error on search and replace
      token:  #{token}
      value:  #{value}
      file:   #{file}
      
      #{e.message}
      #{e.backtrace.join("\n        ")}
/
        end
      }
    end

    def replace_in_files(location, substitutions)
      substitutions.each{ |token,value|
        get_matching_file_list(location, token, value).each do |file|
          warn "    #{file}"
          replace_in_file(file, {token => value})
        end
      }
    end

    def shell_out(command)
      puts "running: #{command}"
      system command
    end

    def shell_out!(command)
      shell_out(command)
      raise "the following command failed with exit_code [#{$?.exitstatus}]:
    #{command}" if $?.exitstatus != 0
    end

  end
end