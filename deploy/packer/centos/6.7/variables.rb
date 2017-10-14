
####################### BEGIN GENERATED CONTENT DONT CHANGE #######################
# [c2f3953cddbc42b25a7cbf4e282d60fe]
######################## END GENERATED CONTENT DONT CHANGE ########################

# Any string value of 'null' below must be set to a new value.

require 'vagrant/project/provider/amazon/helper'
require 'curl'
require 'digest/md5'
require 'open-uri'
require 'git'

access_key Vagrant::Project::Provider::Amazon::Helper.get_aws_credential['aws_access_key_id']
secret_key Vagrant::Project::Provider::Amazon::Helper.get_aws_credential['aws_secret_access_key']

install_vagrant_key 'true'
ssh_password 'vagrant'
ssh_username 'vagrant'

artifact_version "1.0.#{Git.version(File.dirname(__FILE__))}.#{Git.branch_name(File.dirname(__FILE__))}"
vm_short_name $WORKSPACE_SETTINGS[:packer][:context]

scripts_directory_path "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path]}/scripts"
box_output_directory "#{build_directory}/box"
output_directory "#{build_directory}/out"

FileUtils.mkdir_p box_output_directory unless box_output_directory.nil?
FileUtils.mkdir_p output_directory unless output_directory.nil?

remote_iso_url = 'http://archive.kernel.org/centos-vault/6.7/isos/x86_64/CentOS-6.7-x86_64-netinstall.iso'

iso_file_name = File.basename(remote_iso_url)

remote_iso_md5sums_url = 'http://archive.kernel.org/centos-vault/6.7/isos/x86_64/md5sum.txt'

md5_sum_file_content = open(remote_iso_md5sums_url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).string
md5_sums = md5_sum_file_content.lines

iso_checksum md5_sums.grep(/#{iso_file_name}/)[0].chomp.split(' ')[0]

iso_url "#{build_directory}/iso/#{iso_file_name}"

if !File.exist?(iso_url) or Digest::MD5.file(iso_url).hexdigest != iso_checksum
  Curl.large_download(remote_iso_url, iso_url)
end

$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:aws][:ami] = "ami-#{vm_short_name}-#{artifact_version}"
$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:virtualbox][:box][:file] = "#{box_output_directory}/virtualbox/#{vm_short_name}-#{artifact_version}.box"
