require 'packer/baseline_creator'
require 'nexus'
require 'git'


def packer
  return @packer unless @packer.nil?
  @packer = Packer::BaselineCreator.new
end

packer.process_template

desc "build packer vagrant box"
task :packer_build, :packer_opts do |t, args|
  packer_opts = args[:packer_opts] || ''

  packer.build(packer_opts)
end

desc "upload vagrant box to nexus. find vm_short_name from your packer variables.rb; type_opts can be either virtualbox or esxi."
task :upload_box, [:vm_short_name, :type_opts] do |t, args|
  if args[:type_opts].nil?
    upload_box(args[:vm_short_name], 'virtualbox')
  else
    upload_box(args[:vm_short_name], args[:type_opts])
  end
end

def upload_box(vm_short_name, type)
  group_id = "com.vagrantup.basebox.#{vm_short_name.gsub('-', '.')}.#{type}"
  artifact_id = vm_short_name.gsub('.', '-')
  version = "1.0.#{Git.version($WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path])}.#{Git.branch_name(File.dirname(__FILE__))}"
  build_directory = "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:packer][:context][:path]}/.build"
  if type == 'virtualbox'
    artifact_path = "#{build_directory}/box/virtualbox/#{vm_short_name}-#{version}.box"
  else
    artifact_path = "#{build_directory}/box/vmware/#{vm_short_name}-#{version}.box"
  end

  Nexus.upload_artifact(
    group_id: group_id,
    artifact_id: artifact_id,
    artifact_ext: 'box',
    version: version,
    repository: 'filerepo',
    artifact_path: artifact_path
  )
end

desc "create new packer configuration"
task :create_new_packer_configuration, :packer_context do |t, args|
  new_packer_template_path = "#{$WORKSPACE_SETTINGS[:project][:paths][:packer][:home]}/#{args.packer_context}/template.json"

  if File.exist?(new_packer_template_path)
    good "this packer configuration already exists: #{new_packer_template_path}"
    exit 0
  end

  FileUtils.mkdir_p File.dirname(new_packer_template_path)

  FileUtils.touch("#{File.dirname(new_packer_template_path)}/Berksfile")

  File.open(new_packer_template_path, "w"){|file|
    file.write %^
{
  "variables": {
    "install_vagrant_key": "true",
    "ssh_password": "vagrant",
    "ssh_username": "vagrant",
    "artifact_version": null,
    "vm_short_name": null,
    "os_version": null,
    "iso_checksum": null,
    "iso_url": null,
    "scripts_directory_path": null,
    "box_output_directory": null,
    "output_directory": null
  }
}
^
  }

  packer_context_task_path = "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:home]}/packer/#{args.packer_context}/tasks.rb"
  FileUtils.touch packer_context_task_path unless File.exist?(packer_context_task_path)

  packer_context_task_path = File.dirname(args.packer_context)

  while packer_context_task_path != '.'
    FileUtils.touch packer_context_task_path unless File.exist?(packer_context_task_path)
    packer_context_task_path = File.dirname(packer_context_part)
  end

  vagrant_machine_task_path "#{$WORKSPACE_SETTINGS[:paths][:project][:workspace][:settings][:rake][:lib][:tasks][:home]}/vagrant/virtualbox/packer/#{args.packer_context}/tasks.rb"

  FileUtils.mkdir_p File.dirname(vagrant_machine_task_path)

  File.open(new_packer_template_path, "w"){|file|
    file.write %^
require 'vagrant/rake/provider/virtualbox'

provider = Vagrant::Rake::Provider::VirtualBox.new

provider.generate_tasks
^
  }

  new_packer_vagrant_vagrantfile = "#{$WORKSPACE_SETTINGS[:paths][:vagrant_source]}/virtualbox/packer/#{args.packer_context}/Vagrantfile"

  FileUtils.mkdir_p File.dirname(new_packer_vagrant_vagrantfile)

  File.open(new_packer_vagrant_vagrantfile, "w"){|file|
    file.write %^
Vagrant::Project.configure(:blank_virtualbox) do |env|
  blank :"\#{$WORKSPACE_SETTINGS[:packer_vm_short_name]}" do

    vagrant_machine.vm.box = File.basename($WORKSPACE_SETTINGS[:paths][:project_paths_packer_virtualbox_box_file], '.box')
    vagrant_machine.vm.box_url = $WORKSPACE_SETTINGS[:paths][:project_paths_packer_virtualbox_box_file]

  end
end
^
  }
end
