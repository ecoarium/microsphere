require 'shell-helper'
require 'chef/data_bags/reader'

include ShellHelper::Shell

def data_bag_reader
  return @data_bag_reader unless @data_bag_reader.nil?
  @data_bag_reader = Chef::DataBag::Reader.new($WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home])
end

desc "regenerate wildcard cert"
task :regenerate_wildcard_cert do
  secret = data_bag_reader.data_bag_item('microsphere', 'ssl_certificate')[:secret]
  domain_name = data_bag_reader.data_bag_item('microsphere', 'domain_name')[:domain_name]
  Dir.chdir("#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:home]}/certs"){
    generate_wildcard_cert_request(domain_name, secret)
  }
end

desc "generate wildcard cert request"
task :generate_wildcard_cert_request, :domain_name, :secret do |t, args|
  domain_name = args[:domain_name]
  secret = args[:secret]
  generate_wildcard_cert_request(domain_name, secret)
end

def generate_wildcard_cert_request(domain_name, secret)
  script = %^
openssl req -new -newkey rsa:2048 -nodes -keyout #{domain_name}.key -out #{domain_name}.csr <<EOF
US
Virginia
Vienna
MicroStrategy, Inc.
Technology
*.#{domain_name}
administrators@#{domain_name}
#{secret}

EOF
^

  shell_script! script
end
