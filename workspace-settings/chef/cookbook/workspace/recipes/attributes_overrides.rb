#
# Cookbook Name:: workspace
# Recipe:: attributes_overrides
#

node.override[:packer][:url] = 'https://releases.hashicorp.com/packer/0.11.0/packer_0.11.0_darwin_amd64.zip'
node.override[:packer][:version] = '0.11.0'
node.override[:packer][:checksum] = '5e3c3448f0efc33069ecfeae698eea475b37ebff385db596f6f4621edfd52797'

node.override[:virtualbox][:version]  = '5.0.20-106931'
