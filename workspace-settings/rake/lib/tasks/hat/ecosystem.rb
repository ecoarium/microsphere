require 'shell-helper'
require 'git'
require 'jenkins'

include ShellHelper::Shell

desc "publish version of ecosystem"
task :publish_ecosystem do
  ecosystem_dir = File.expand_path("github/ecoarium/ecosystem", $WORKSPACE_SETTINGS[:paths][:projects][:root])
  require "#{ecosystem_dir}/version.rb"

  Git.up_to_date?(ecosystem_dir)
  raise "please ensure the ecosystem repo is up to date with no outstanding untracked or staged files and all commits have been pushed" unless Git.up_to_date?(ecosystem_dir)

  version = Ecosystem::Version.current_version

  [
    "git tag #{version}",
    'git push origin',
    "git push origin : #{version}"
  ].each{|command|
    shell_command! command, cwd: ecosystem_dir
  }

end
