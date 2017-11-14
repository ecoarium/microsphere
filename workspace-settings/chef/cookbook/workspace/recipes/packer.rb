#
# Cookbook Name:: workspace
# Recipe:: packer
#

include_recipe "ark"

ark 'packer' do
    url node[:packer][:url]
    version node[:packer][:version]
    checksum node[:packer][:checksum]
    strip_components 0
end
