
####################### BEGIN GENERATED CONTENT DONT CHANGE #######################
# [b927700ab4eec90401af5b6c8c0c7c85]
######################## END GENERATED CONTENT DONT CHANGE ########################

# Any string value of 'null' below must be set to a new value.

require 'vagrant/project/provider/amazon/helper'
require 'curl'
require 'digest/md5'
require 'open-uri'
require 'git'

aws_region $WORKSPACE_SETTINGS[:aws][:region]

# https://wiki.centos.org/Cloud/AWS
amis = {
  "ap-northeast-1" => "ami-f61c3e91",
  "ap-northeast-2" => "ami-fecb1990",
  "ap-south-1" => "ami-e6f48789",
  "ap-southeast-1" => "ami-4d348a2e",
  "ap-southeast-2" => "ami-7a959b19",
  "ca-central-1" => "ami-00e45864",
  "eu-central-1" => "ami-11a2707e",
  "eu-west-1" => "ami-8f043ee9",
  "eu-west-2" => "ami-bf2c38db",
  "sa-east-1" => "ami-19492b75",
  "us-east-1" => "ami-500d8546",
  "us-east-2" => "ami-7dbe9a18",
  "us-west-1" => "ami-252a0f45",
  "us-west-2" => "ami-112cbc71",
}

aws_ami amis[$WORKSPACE_SETTINGS[:aws][:region]]

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
