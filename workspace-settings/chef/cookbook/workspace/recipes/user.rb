#
# Cookbook Name:: workspace
# Recipe:: user
#

include_recipe 'workspace::project'

case node['platform']
when 'windows'
  # include_recipe 'virtualbox'
else
  #probably not
end
