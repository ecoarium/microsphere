require 'json'
require 'tmpdir'
require "erb"
require 'chef/data_bags/reader'

def data_bag_reader
  return @data_bag_reader unless @data_bag_reader.nil?
  @data_bag_reader = Chef::DataBag::Reader.new($WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home])
end

desc "list data bag items"
task :list_data_bag_items, :data_bag_name_opt do |t, args|
  if args[:data_bag_name_opt].nil?
    puts JSON.pretty_generate(data_bag_reader.data_bags)
  else
    puts JSON.pretty_generate(data_bag_reader.data_bags_items(args[:data_bag_name_opt]))
  end
end

desc "show data bag item"
task :show_data_bag_item, :data_bag_name, :data_bag_item_name do |t, args|
  puts JSON.pretty_generate(data_bag_reader.data_bag_item(args[:data_bag_name], args[:data_bag_item_name]))
end

desc "create data bag items for users"
task :create_users_data_bag_items, :team_info_file do |t, args|
  team_info_file = args[:team_info_file]
  contacts = Outlook::Contacts.new(team_info_file)
  contacts.create_user_data_bag_items
end

desc "create data bag cert"
task :create_data_bag_aws_key_pair, :key_pair_name do |t, args|
  key_pair_name = args.key_pair_name

  key_file_path = File.expand_path("aws/keys/#{key_pair_name}", $WORKSPACE_SETTINGS[:paths][:organization][:vagrant][:home])

  data_bag_name = key_pair_name

  data_bag_item = {
    :id => data_bag_name,
    :ssh_cert_file => File.readlines(key_file_path)
  }

  data_bag_item_file = File.expand_path("aws/#{data_bag_name}.json", $WORKSPACE_SETTINGS[:paths][:project][:deploy][:chef][:data][:bags][:home])

  FileUtils.mkdir_p File.dirname(data_bag_item_file) unless File.exist?(File.dirname(data_bag_item_file))

  File.open(data_bag_item_file, "w") { |file| file.write(data_bag_item.to_json.gsub(/\\n/, '')) }

  Rake::Task["encrypt_data_bag"].invoke('aws', data_bag_name)
end

desc "configure aws security"
task :configure_aws_security do
  data_bag_reader.data_bags_items('aws').each{|data_bag_item_name, data_bag_item|
    if data_bag_item[:id] == 'api'
      fog_file_path = File.expand_path('.fog', $WORKSPACE_SETTINGS[:paths][:company][:home])

      File.open(fog_file_path, "w"){|file|
        file.write "default:
  aws_access_key_id: #{data_bag_item[:key]}
  aws_secret_access_key: #{data_bag_item[:secret]}"
      }
      next
    end

    key_folder_path = File.expand_path("aws/keys", $WORKSPACE_SETTINGS[:paths][:organization][:vagrant][:home])
    key_file_path = File.expand_path(data_bag_item[:id], key_folder_path)

    FileUtils.mkdir_p key_folder_path unless File.exist?(key_folder_path)
    FileUtils.chmod 0700, key_folder_path

    File.open(key_file_path, "w"){|file|
      file.write data_bag_item[:ssh_cert_file].join("\n")
    }
    FileUtils.chmod 0600, key_file_path
  }
end
