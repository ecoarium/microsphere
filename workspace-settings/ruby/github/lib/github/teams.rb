require 'logging-helper'
require 'httparty'
require 'json'
require 'uri'

module Github
  class Teams
    include LoggingHelper::LogToTerminal
    include HTTParty
    default_params :output => 'json'
    format :json

    def initialize(username, password, base_url='https://api.github.com')
      @username = username
      @password = password
      @base_url = base_url
    end

    def create_team_members(organization_name, team_name, permission, users, maintainers)
      team = ensure_team_created(organization_name, team_name, permission, maintainers)
      users.each{|user|
        add_member(team['id'], user) unless member?(team['id'], user)
      }
    end

    def ensure_team_created(organization_name, team_name, permission, maintainers)
      team = find(team_name, organization_name)
      team = create(organization_name, team_name, permission, maintainers) if team.nil?
      team
    end

    def create(organization_name, team_name, permission, maintainers)
      post(
        "#{base_url}/orgs/#{organization_name}/teams",
        basic_auth:{
          username: username,
          password: password
        },
        headers: {
          'accept' => 'application/vnd.github.korra-preview+json'
        },
        body:{
          name: team_name,
          permission: permission,
          maintainers: maintainers
        }.to_json
      )
    end

    def member?(team_id, user)
      get(
        "#{base_url}/teams/#{team_id}/memberships/#{user}",
        basic_auth:{
          username: username,
          password: password
        }
      ).code == 200
    end

    def add_member(team_id, user)
      put(
        "#{base_url}/teams/#{team_id}/memberships/#{user}",
        basic_auth:{
          username: username,
          password: password
        },
        query:{
          role: 'member'
        }
      )
    end

    def add_repository(team_id, permission, organization_name, repository_name)
      put(
        "#{base_url}/teams/#{team_id}/repos/#{organization_name}/#{repository_name}",
        basic_auth:{
          username: username,
          password: password
        },
        body:{
          permission: permission
        }.to_json
      )
    end

    def remove_repository(team_id, organization_name, repository_name)
      delete(
        "#{base_url}/teams/#{team_id}/repos/#{organization_name}/#{repository_name}",
        basic_auth:{
          username: username,
          password: password
        }
      )
    end

    def list_team_repos(team_id)
      get(
        "#{base_url}/teams/#{team_id}/repos",
        basic_auth:{
          username: username,
          password: password
        }
      )
    end

    def find(team_name, organization_name)
      debug{"find(#{team_name}, #{organization_name})"}
      teams(organization_name).find{|team|
        team['name'] == team_name
      }
    end

    def exist?(team_name, organization_name)
      !find(team_name, organization_name).nil?
    end

    def update_team_permission(team_id, team_name, permission)
      debug {"updating team permission for #{team_name}"}
      patch(
        "#{base_url}/teams/#{team_id}",
        basic_auth:{
          username: username,
          password: password
        },
        body:{
          name: team_name,
          permission: permission
        }.to_json
      )
    end

    def teams(organization_name)
      debug {"teams(#{organization_name})"}
      team_list = []
      team_paged_list = get(
        "#{base_url}/orgs/#{organization_name}/teams",
        basic_auth:{
          username: username,
          password: password
        }
      )
      team_list.concat team_paged_list
      headers = team_paged_list.headers
      while !headers['Link'].nil?
        next_page = headers['Link'].split(';')[0][/<(.*)>/, 1]

        break unless next_page =~ /\A#{URI::regexp(['http', 'https'])}\z/
        break if next_page.end_with?('page=1')
        debug {"next_page -> #{next_page}"}

        team_paged_list = get(
          next_page,
          basic_auth:{
            username: username,
            password: password
          }
        )

        team_list.concat team_paged_list
        headers = team_paged_list.headers
      end
      team_list
    end

    def members(team_name, organization_name, role, opts={})
      debug{"members(#{team_name}, #{organization_name}, #{opts.inspect})"}
      team_id = find(team_name, organization_name)['id']
      member_list = []
      member_paged_list = get(
        "#{base_url}/teams/#{team_id}/members?role=#{role}",
        basic_auth:{
          username: username,
          password: password
        },
        query: opts
      )
      member_list.concat member_paged_list
      headers = member_paged_list.headers
      while !headers['Link'].nil?
        next_page = headers['Link'].split(';')[0][/<(.*)>/, 1]

        break unless next_page =~ /\A#{URI::regexp(['http', 'https'])}\z/
        break if next_page.end_with?('page=1')
        debug {"next_page -> #{next_page}"}

        member_paged_list = get(
          next_page,
          basic_auth:{
            username: username,
            password: password
          },
          query: opts
        )

        member_list.concat member_paged_list
        headers = member_paged_list.headers
      end
      member_list
    end

    private
    attr_reader :username, :password, :base_url

    def method_missing(method_symbol, *args, &block)
      unless self.class.respond_to?(method_symbol)
        raise "method not found: #{method_symbol}. It's not on this class: #{self.inspect}, and HTTParty does not respond_to the method either."
      end

      self.class.method(method_symbol).call(*args, &block)
    end
  end
end
