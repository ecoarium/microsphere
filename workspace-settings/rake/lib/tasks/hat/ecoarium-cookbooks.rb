require 'erb'
require 'shell-helper'
require 'git'
#require 'github'
require 'terminal-helper/ask'

desc "create new cookbook"
task :create_new_ecoarium_cookbook, :cookbook_name do |t, args|
  cookbook_name = args[:cookbook_name]
  organization_name = 'ecoarium-cookbooks'
  team_name = 'devops-ecoarium-cookbooks'

  workspace = File.expand_path("github/#{organization_name}", $WORKSPACE_SETTINGS[:paths][:projects][:root])

  # ensure_repo_exist(cookbook_name, organization_name, team_name)

  shell_command! "knife cookbook create #{cookbook_name} --cookbook-path #{workspace}"

  cookbook_path = File.expand_path(cookbook_name, workspace)

  git_url = "https://github.com/#{organization_name}/#{cookbook_name}.git"

  Dir.chdir(cookbook_path){
    [
      'git init .',
      "git remote add origin #{git_url}"
    ].each{|command|
      shell_command! command
    }
  }
end

def ensure_repo_exist(repo_name, organization_name, team_name)
  organization = data_bag_reader.data_bag_item('organizations', organization_name)

  unless repo_exist_in_organization_data_bag_item?(repo_name, organization)
    configure_repo_in_organization_data_bag_item(repo_name, organization, team_name)
    github_manage_organization(organization_name)
  end
end

def repo_exist_in_organization_data_bag_item?(repo_name, organization)
  organization[:repositories].any?{|repo_info| repo_info[:name] == repo_name}
end

def configure_repo_in_organization_data_bag_item(repo_name, organization, team_name)
  new_repo = {
    name: repo_name,
    template: nil,
    teams: [
      "team_name": team_name,
      "team_permission": "pull"
    ]
  }

  organization[:repositories] << new_repo

  json_organization = JSON.pretty_generate organization
  File.open("#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home]}/organizations/#{organization[:id]}.json","w") {|file|
    file.write(json_organization)
  }
end

def git_up_to_date?
  status_command = "git status -uno -u"
  status = shell_output! "#{status_command}"

  up_to_date = status.include?('Your branch is up-to-date with')
  no_unstaged_files = !status.include?('Changes not staged for commit')
  no_untracked_files = !status.include?('Untracked files')

  up_to_date and no_unstaged_files and no_untracked_files
end

desc "publish initial cookbook: publish_initial_cookbook[*cookbook_name*,?organization_name?,?team_name?]"
task :publish_initial_cookbook, :cookbook_name, :organization_name_opt, :team_name_opt do |t, args|
  cookbook_name = args[:cookbook_name]
  raise 'you must supply a cookbook name' if cookbook_name.nil?

  organization_name = 'ecoarium-cookbooks' || args[:organization_name_opts]
  team_name = 'devops-ecoarium-cookbooks' || args[:team_name_opts]

  cookbook_path = File.expand_path("github/ecoarium-cookbooks/#{cookbook_name}", $WORKSPACE_SETTINGS[:paths][:projects][:root])

  git_url = "https://github.com/#{organization_name}/#{cookbook_name}.git"

  username = ask_for_input("please enter your user name:")
  password = ask_for_sensative_input("please enter your password:")

  org_manager = Github::Organization.new(username, password, data_bag_reader)
  client = org_manager.client
  opts = {
    organization: organization_name,
    team_id: 133,
    has_issues: false,
    has_wiki: false,
    has_downloads: false,
    accept: 'application/json'
  }
  client.create_repository(cookbook_name, opts) unless client.repository?("#{organization_name}/#{cookbook_name}")
  # client.add_team_repository(132, "#{organization_name}/#{cookbook_name}", accept: '*/*', headers: {content_length: '0'})
  # client.add_team_repository(133, "#{organization_name}/#{cookbook_name}", accept: '*/*', headers: {content_length: '0'})

  Dir.chdir(cookbook_path){
    [
      # 'git init .',
      # "git remote add origin #{git_url}",
      'git add -A',
      'git commit -m \'inital commit\'',
      'git push -u origin master'
    ].each{|command|
      shell_command! command
    }
  }

  # publish_cookbook(cookbook_name)
end

desc "publish cookbook: publish_cookbook[*cookbook_name*]"
task :publish_cookbook, :cookbook_name do |t, args|
  cookbook_name = args[:cookbook_name]
  raise 'you must supply a cookbook name' if cookbook_name.nil?

  publish_cookbook(cookbook_name)
end

def publish_cookbook(cookbook_name)
  cookbook_path = File.expand_path("github/ecoarium-cookbooks/#{cookbook_name}", $WORKSPACE_SETTINGS[:paths][:projects][:root])
  version = write_version_to_meta_data_file(cookbook_path, version)

  debug{
    "publish_cookbook(#{cookbook_name})
    #{version}
    #{cookbook_path}
    "
  }

  Dir.chdir(cookbook_path){
    [
      'git pull',
      'git add -A',
      "git commit -m 'commit for version : #{version}'",
      "git tag #{version}",
      'git push origin',
      "git push origin : #{version}"
    ].each{|command|
      shell_command! command
    }
  }
end

def write_version_to_meta_data_file(cookbook_path, version)
  meta_data_file_path = File.join(cookbook_path, 'metadata.rb')

  build_number = get_build_version(cookbook_path)

  content = File.read(meta_data_file_path)

  content.gsub!(/(version\s+["|']\d+\.\d+\.)\d+(["|'])/, '\1' + build_number + '\2')

  version = content[/version\s+["|'](\d+\.\d+\.\d+)["|']/, 1]

  File.open(meta_data_file_path, "w") do |file|
    file.write content
  end
  version
end

def get_build_version(cookbook_path)
  build_number = Git.version(cookbook_path)
end

def data_bag_reader
  return @data_bag_reader unless @data_bag_reader.nil?
  @data_bag_reader = Chef::DataBag::Reader.new($WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home])
end
