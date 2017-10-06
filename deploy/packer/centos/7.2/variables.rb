
####################### BEGIN GENERATED CONTENT DONT CHANGE #######################
# []
######################## END GENERATED CONTENT DONT CHANGE ########################

# Any string value of 'null' below must be set to a new value.

require 'curl'
require 'digest/md5'
require 'open-uri'
require 'git'

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

remote_iso_url = 'http://archive.kernel.org/centos-vault/7.2.1511/isos/x86_64/CentOS-7-x86_64-NetInstall-1511.iso'

iso_file_name = File.basename(remote_iso_url)

remote_iso_md5sums_url = 'http://archive.kernel.org/centos-vault/7.2.1511/isos/x86_64/md5sum.txt'

md5_sum_file_content = open(remote_iso_md5sums_url, {ssl_verify_mode: OpenSSL::SSL::VERIFY_NONE}).string
md5_sums = md5_sum_file_content.lines

iso_checksum md5_sums.grep(/#{iso_file_name}/)[0].chomp.split(' ')[0]

iso_url "#{build_directory}/iso/#{iso_file_name}"

if !File.exist?(iso_url) or Digest::MD5.file(iso_url).hexdigest != iso_checksum
  Curl.large_download(remote_iso_url, iso_url)
end

$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:virtualbox][:box][:file] = "#{box_output_directory}/virtualbox/#{vm_short_name}-#{artifact_version}.box"
