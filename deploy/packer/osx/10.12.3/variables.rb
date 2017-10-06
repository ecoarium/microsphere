
####################### BEGIN GENERATED CONTENT DONT CHANGE #######################
# [09dae23759fac35ea30c122782ed4a33]
######################## END GENERATED CONTENT DONT CHANGE ########################

# Any string value of 'null' below must be set to a new value.

require 'fileutils'
require 'curl'
require 'open-uri'
require 'digest/md5'
require 'git'

install_vagrant_key 'true'
password 'vagrant'
username 'vagrant'
artifact_version "1.0.#{Git.version(File.dirname(__FILE__))}.#{Git.branch_name(File.dirname(__FILE__))}"

os_name, os_version = $WORKSPACE_SETTINGS[:packer][:context].split('/')

vm_short_name "#{os_name}-#{os_version}"

scripts_directory_path "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path]}/scripts"
box_output_directory "#{build_directory}/box"
output_directory "#{build_directory}/out"

FileUtils.mkdir_p box_output_directory unless box_output_directory.nil?
FileUtils.mkdir_p output_directory unless output_directory.nil?

remote_iso_url = "#{$WORKSPACE_SETTINGS[:nexus][:direct_base_path]}/#{$WORKSPACE_SETTINGS[:nexus][:repos][:file]}/com/apple/installesd/#{os_version}/installesd-#{os_version}.dmg"

iso_file_name = File.basename(remote_iso_url)

remote_iso_md5sums_url = "#{remote_iso_url}.md5"

iso_checksum open(remote_iso_md5sums_url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).string.chomp

iso_flag_file = "#{build_directory}/iso/flag"
FileUtils.touch iso_flag_file unless File.exist?(iso_flag_file)

iso_url "#{build_directory}/iso/#{iso_file_name}"

if !File.exist?(iso_url) or File.read(iso_flag_file) != iso_checksum
  Curl.large_download(remote_iso_url, iso_url)

  File.open(iso_flag_file, "w"){|file|
    file.write Digest::MD5.file(iso_url).hexdigest
  }
end

$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:virtualbox][:box][:file] = "#{box_output_directory}/virtualbox/#{vm_short_name}-#{artifact_version}.box"
