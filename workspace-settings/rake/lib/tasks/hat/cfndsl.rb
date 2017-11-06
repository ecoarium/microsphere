require 'cfndsl/rake_task'
require 'cfndsl-ext'
require 'aws-sdk'
require 'json'
require 'yaml'

CfnDsl::RakeTask.new('cfndsl_generate_template') do |t|
  FileUtils.mkdir_p $WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:state] unless File.exist?($WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:state])
  
  t.cfndsl_opts = {
    verbose: true,
    files: [{
      filename: $WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:context][:cfndslfile],
      output: "#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:state]}/cfn.json"
    }]
  }
end

desc "deploy cfn file"
task :cfndsl_deploy => [:cfndsl_generate_template] do
    name = 'dev'
    todo "need to create a menaingful name for the stack, remember that these will be made from all team member workspaces...", "11/15/2017 02:00 PM"
    tags = CfndslExt::Tagging.generate_tags(name: name)

    stack = CfndslExt::CloudFormation::Stack.new(
      name,
      {
        region: 'us-east-2',
        access_key_id: credentials[:key],
        secret_access_key: credentials[:secret]
      }
    )

    if stack.exists?
      stack.update(
        template_body: File.read("#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:state]}/cfn.json"),
        tags: tags
      )
    else
      stack.create(
        template_body: File.read("#{$WORKSPACE_SETTINGS[:paths][:project][:deploy][:cfndsl][:state]}/cfn.json"),
        tags: tags
      )
    end

end

def credentials
  return @aws_credentials unless @aws_credentials.nil?
  config_file = ENV.has_key?("FOG_RC") ? ENV['FOG_RC'] : "#{ENV['HOME']}/.fog"
  unless File.exist?(config_file)
    raise %/
      Couldn't find .fog file, environment variable FOG_RC exists? -> #{ENV.has_key?("FOG_RC").inspect}
      looked for .fog file in: #{config_file}

      Put your credentials in the .fog file as follows:

      default:
          aws_access_key_id: YOUR_ACCESS_KEY_ID
          aws_secret_access_key: YOUR_SECRET_ACCESS_KEY
    /
  end

  fog_credentials = YAML.load(File.read(config_file))

  unless fog_credentials["default"] and fog_credentials["default"]["aws_access_key_id"] and fog_credentials["default"]["aws_secret_access_key"]
    raise %/
      deserialized file content:
      #{fog_credentials.pretty_inspect}

      #{config_file} is formatted incorrectly.  Please use the following format:

      default:
          aws_access_key_id: YOUR_ACCESS_KEY_ID
          aws_secret_access_key: YOUR_SECRET_ACCESS_KEY
    /
  end

  @aws_credentials = {
    key: fog_credentials["default"]['aws_access_key_id'],
    secret: fog_credentials["default"]['aws_secret_access_key']
  }
  @aws_credentials
end
