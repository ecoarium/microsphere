require 'chef/data_bags/reader'
require 'terminal-helper/ask'
require 'common/version'
require 'vagrant/shell'
require 'tmpdir'
require 'nexus'

include Vagrant::Shell
include TerminalHelper::AskMixin

def data_bag_reader
  return @data_bag_reader unless @data_bag_reader.nil?
  @data_bag_reader = Chef::DataBag::Reader.new($WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home])
end


desc "repackage and publish vagrant box to nexus"
task :repackage_and_publish_vagrant_box, :box_name, :provider_opt, :version_opt do |me, box_name, provider_opt, version_opt|
  box_info = {providers: []}

  raw_vagrant_execution('box list').stdout.split("\n").each{|line|\
    line = line.scan(/[[:print:]]/).join
    line.gsub!(/\[0m/, '')
    trash, listed_box_name, listed_box_provider, listed_box_version = line.split(/^(\S+)\s+\((\S+),\s(\S+)\)/)
    
    if listed_box_name == box_name
      box_info[:providers].push listed_box_provider unless box_info[:providers].include?(listed_box_provider)
      box_info[listed_box_provider] = {versions: []} if box_info[listed_box_provider].nil?
      box_info[listed_box_provider][:versions].push listed_box_version 
    end
  }

  raise "can't find the box '#{box_name}' in list:
#{box_info.pretty_inspect}
" if box_info[:providers].empty?

  raise "the provider #{provider_opt} not found in listed providers:
  * #{box_info[:providers].join("\n  * ")}
" if !provider_opt.nil? and !box_info[:providers].include?(provider_opt)

  if box_info[:providers].size > 1
    provider_opt = ask_with_options("Please choose the provider for box #{box_name}:", box_info[:providers])
  else
    provider_opt = box_info[:providers].first
  end

  raise "the version #{version_opt} not found in listed versions:
  * #{box_info[provider_opt][:versions].join("\n  * ")}
" if !version_opt.nil? and !box_info[provider_opt][:versions].include?(version_opt)

  if box_info[provider_opt][:versions].size > 1
    version_opt = ask_with_options("Please choose the version for box #{box_name} and provider #{provider_opt}:", box_info[provider_opt][:versions])
  else
    version_opt = box_info[provider_opt][:versions].first
  end

  Dir.mktmpdir{|temp_dir|
    credentials = data_bag_reader.data_bag_item('credentials', 'nexus')

    $WORKSPACE_SETTINGS[:nexus][:credentials] = {
      user_name: credentials[:username],
      password: credentials[:password]
    }

    box_file_path = "#{temp_dir}/package.box"

    raw_vagrant_execution(
      "box repackage #{box_name} #{provider_opt} #{version_opt}",
      cwd: temp_dir
    )

    artifact_id = box_name[/(.*)-\d+\.\d+\.\d+\.[\w|-]+$/,1].gsub(/\./, '-')

    Nexus.upload_artifact(
      group_id:       "com.vagrantup.basebox.#{artifact_id.gsub(/-/, '.')}.#{provider_opt}",
      artifact_id:    artifact_id,
      artifact_ext:   'box',
      version:        box_name[/-(\d+\.\d+\.\d+\.[\w|-]+)$/,1],
      repository:     $WORKSPACE_SETTINGS[:nexus][:repos][:file],
      artifact_path:  box_file_path
    )
  }
end

