#
# Cookbook Name:: workspace
# Recipe:: project
#

include_recipe 'chef_commons'
include_recipe 'workspace::attributes_overrides'

include_recipe 'workspace::packer'
