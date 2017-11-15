require 'vagrant/rake/provider/virtualbox'

provider = Vagrant::Rake::Provider::VirtualBox.new
provider.generate_tasks
