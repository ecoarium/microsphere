require 'logging-helper'

module Github
  class Manager
    include LoggingHelper::LogToTerminal

    attr_reader :username, :password, :data_bag_reader

    def initialize(username, password, data_bag_reader)
      @username = username
      @password = password
      @data_bag_reader = data_bag_reader
    end


    def manage_organization(organization_information)
      organizations = Organizations.new(username, password)
      organizations.create(organization_information[:id], organization_information[:id], username) unless organizations.exist?(organization_information[:id])

      organization_information[:teams].each{|team_name|

        team_info = data_bag_reader.data_bag_item('teams', team_name)
        users = team_info[:members].collect{|info| info[:user_data_bag_item_name] }
        maintainers = team_info[:maintainers].collect{|info| info[:user_data_bag_item_name] }
        permission = team_info[:systems][0][:permission_level]
        organizations.add_memebers(organization_information[:id], users)

        teams = Teams.new(username, password)
        teams.create_team_members(organization_information[:id], team_name, permission, users, maintainers)
      }

      repositories = Repositories.new(username, password)
      organization_information[:repositories].each{|repo_info|
        repositories.create(repo_info[:name], organization_information[:id], repo_info[:teams], repo_info[:template])
      }
    end
  end
end
