#
# Cookbook Name:: workspace
# Recipe:: project
#

include_recipe 'chef_commons'
include_recipe 'workspace::attributes_overrides'

# case node['platform']
# when 'redhat', 'centos', 'fedora'
#   include_recipe 'java'
# when 'windows'
#   include_recipe 'java-windows'
# else
#   Chef::Application.fatal!("this OS is not supported: #{node['platform']}")
# end
#
# include_recipe 'gradle'

# include_recipe 'workspace::packer'
