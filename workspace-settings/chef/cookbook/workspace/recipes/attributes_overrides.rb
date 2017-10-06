#
# Cookbook Name:: workspace
# Recipe:: attributes_overrides
#

java_minor_version = 8
java_patch_version = 45
java_osx_checksum = 'replace'
java_windows_checksum = 'replace'

case node['platform']
when 'redhat', 'centos', 'fedora'
  node.override[:java].deep_merge!({
    install_flavor: 'oracle_rpm',
    java_home: "/usr/java/jdk1.#{java_minor_version}.0_#{java_patch_version}",
    oracle_rpm: {
      type: 'jdk',
      package_version: "1.#{java_minor_version}.0_#{java_patch_version}-fcs",
      package_name: "jdk1.#{java_minor_version}.0_#{java_patch_version}"
    }
  })
when 'windows'
  node.override[:java].deep_merge!({
    windows: {
      java_home: "C:\\Java\\jdk1.#{java_minor_version}.0_#{java_patch_version}",
      checksum: java_windows_checksum,
      url: "http://jayflowers.com/#{java_minor_version}u#{java_patch_version}/windows-#{java_minor_version}u#{java_patch_version}-x64.exe"
    }
  })
else
  Chef::Application.fatal!("this OS is not supported: #{node['platform']}")
end

node.override[:gradle].deep_merge!(
  source: 'https://services.gradle.org/distributions/gradle-3.5-bin.zip',
  checksum: 'b29ccc5be25f0446183edc4f144673934bd7bb7e',
  version: '3.5'
)

node.override[:packer][:url] = 'https://releases.hashicorp.com/packer/0.11.0/packer_0.11.0_darwin_amd64.zip'
node.override[:packer][:version] = '0.11.0'
node.override[:packer][:checksum] = '5e3c3448f0efc33069ecfeae698eea475b37ebff385db596f6f4621edfd52797'

node.override[:virtualbox][:version]  = '5.0.20-106931'
