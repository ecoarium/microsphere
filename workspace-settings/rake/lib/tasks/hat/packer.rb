require 'fileutils'

require "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:home]}/packer/#{$WORKSPACE_SETTINGS[:packer][:context]}/tasks.rb"

packer_context_part = File.dirname($WORKSPACE_SETTINGS[:packer][:context])

while packer_context_part != '.'
  require "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:home]}/packer/#{packer_context_part}/tasks.rb"
  packer_context_part = File.dirname(packer_context_part)
end

require "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:home]}/packer/tasks.rb"

