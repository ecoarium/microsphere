
####################### BEGIN GENERATED CONTENT DONT CHANGE #######################
# [c3112f95fdbff442cdcd9404aaa0ad87]
######################## END GENERATED CONTENT DONT CHANGE ########################

# Any string value of 'null' below must be set to a new value.

# https://github.com/joefitzgerald/packer-windows

require 'curl'
require 'digest/md5'
require 'open-uri'
require 'git'

artifact_version "1.0.#{Git.version(File.dirname(__FILE__))}.#{Git.branch_name(File.dirname(__FILE__))}"
vm_short_name $WORKSPACE_SETTINGS[:packer][:context]

puts "preparing to create vagrant box(es) with packer: #{vm_short_name}-#{artifact_version}"

scripts_directory_path "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path]}/scripts"
box_output_directory "#{build_directory}/box"
output_directory "#{build_directory}/out"

FileUtils.mkdir_p box_output_directory unless box_output_directory.nil?
FileUtils.mkdir_p output_directory unless output_directory.nil?

remote_iso_url = 'http://download.microsoft.com/download/7/5/E/75EC4E54-5B02-42D6-8879-D8D3A25FBEF7/7601.17514.101119-1850_x64fre_server_eval_en-us-GRMSXEVAL_EN_DVD.iso'
iso_file_name = File.basename(remote_iso_url)


iso_url "#{build_directory}/iso/#{iso_file_name}"
iso_checksum_type 'md5'
iso_checksum '4263be2cf3c59177c45085c0a7bc6ca5'
autounattend "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path]}/answer_files/2008_r2/Autounattend.xml"

if !File.exist?(iso_url) or Digest::MD5.file(iso_url).hexdigest != iso_checksum
  Curl.large_download(remote_iso_url, iso_url)
end

$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:virtualbox][:box][:file] = "#{box_output_directory}/virtualbox/#{vm_short_name}-#{artifact_version}.box"
