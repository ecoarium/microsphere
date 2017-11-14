#
# Cookbook Name:: workspace
# Recipe:: user
#

include_recipe 'workspace::project'

include_recipe 'virtualbox'

include_recipe 'atom-organism'
