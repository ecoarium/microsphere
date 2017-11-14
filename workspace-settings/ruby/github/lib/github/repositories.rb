require 'logging-helper'
require 'github/sculptor'
require 'httparty'
require 'json'
require 'uri'

module Github
  class Repositories
    include LoggingHelper::LogToTerminal
    include HTTParty
    default_params :output => 'json'
    format :json

    def initialize(username, password, base_url='https://api.github.com')
      @username = username
      @password = password
      @base_url = base_url
    end

    def create(repository_name, organization_name, teams_info, template=nil)
      unless exist?(repository_name, organization_name)
        response = post(
          "#{base_url}/orgs/#{organization_name}/repos",
          basic_auth:{
            username: username,
            password: password
          },
          body:{
            name: repository_name,
            description: '',
            homepage: '',
            private: false,
            has_issues: false,
            has_wiki: false,
            has_downloads: false,
          }.to_json
        )
        unless response.code == 201
          error response.body
          error response.headers.pretty_inspect
          raise "Failed with response code #{response.code}"
        end

        unless template.nil?
          apply_template_to_repo(repository_name, organization_name, template)
        end
      end

      teams = Teams.new(username, password)
      teams_info.each{|team_info|
        team = teams.find(team_info[:team_name], organization_name)
        teams.add_repository(
          team['id'],
          team_info[:team_permission],
          organization_name,
          repository_name
        )
      }
    end

    def apply_template_to_repo(repository_name, organization_name, template)
      uri = URI.parse(base_url)
      uri.path = ''
      github_url = uri.to_s

      mud_repo_name = template[:repo_name]
      mud_org_name = template[:org_name]
      mud_repo_url = "#{github_url}/#{mud_org_name}/#{mud_repo_name}.git"

      if template[:ecosystem_domain_name].nil?
        ecosystem_domain_name = data_bag_reader.data_bag_item('ecosystem', 'domain_name')[:domain_name]
      else
        ecosystem_domain_name = template[:ecosystem_domain_name]
      end
      project_parent_name = "#{organization_name}"
      project_name = repository_name
      project_git_repo_url = "#{github_url}/#{organization_name}/#{project_name}.git"

      sculptor = Sculptor.new(mud_repo_name, mud_repo_url, ecosystem_domain_name, project_parent_name, project_name, project_git_repo_url)
      sculptor.populate_repo
    end

    def commits(organization_name, repository_name, branch_name)
      list = []
      paged_list = get(
        "#{base_url}/repos/#{organization_name}/#{repository_name}/commits",
        basic_auth:{
          username: username,
          password: password
        }
      )
      list.concat paged_list
      headers = paged_list.headers
      while !headers['Link'].nil?
        next_page = headers['Link'].split(';')[0][/<(.*)>/, 1]

        break unless next_page =~ /\A#{URI::regexp(['http', 'https'])}\z/
        break if next_page.end_with?('page=1')
        debug {"next_page -> #{next_page}"}

        paged_list = get(
          next_page,
          basic_auth:{
            username: username,
            password: password
          }
        )

        list.concat paged_list
        headers = paged_list.headers
      end
      list
    end

    def create_ref(organization_name, repository_name, ref, sha)
      post(
        "#{base_url}/repos/#{organization_name}/#{repository_name}/git/refs",
        basic_auth:{
          username: username,
          password: password
        },
        query:{
          ref: ref,
          sha: sha
        }
      )
    end


    def repositories(organization_name)
      repository_list = []
      repository_paged_list = get(
        "#{base_url}/orgs/#{organization_name}/repos",
        basic_auth:{
          username: username,
          password: password
        }
      )
      repository_list.concat repository_paged_list
      headers = repository_paged_list.headers
      while !headers['Link'].nil?
        next_page = headers['Link'].split(';')[0][/<(.*)>/, 1]

        break unless next_page =~ /\A#{URI::regexp(['http', 'https'])}\z/
        break if next_page.end_with?('page=1')
        debug {"next_page -> #{next_page}"}

        repository_paged_list = get(
          next_page,
          basic_auth:{
            username: username,
            password: password
          }
        )

        repository_list.concat repository_paged_list
        headers = repository_paged_list.headers
      end
      repository_list
    end

    def exist?(repo_name, org_name)
      repository = get(
        "#{base_url}/repos/#{org_name}/#{repo_name}",
        basic_auth:{
          username: username,
          password: password
        }
      )
      repository.code == 200
    end

    def teams(organization_name, repository_name)
      team_list = []
      team_paged_list = get(
        "#{base_url}/repos/#{organization_name}/#{repository_name}/teams",
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

    def hooks(organization_name, repository_name)
      hook_list = []
      hook_paged_list = get(
        "#{base_url}/repos/#{organization_name}/#{repository_name}/hooks",
        basic_auth:{
          username: username,
          password: password
        }
      )
      hook_list.concat hook_paged_list
      headers = hook_paged_list.headers
      while !headers['Link'].nil?
        next_page = headers['Link'].split(';')[0][/<(.*)>/, 1]

        break unless next_page =~ /\A#{URI::regexp(['http', 'https'])}\z/
        break if next_page.end_with?('page=1')
        debug {"next_page -> #{next_page}"}

        hook_paged_list = get(
          next_page,
          basic_auth:{
            username: username,
            password: password
          }
        )

        hook_list.concat hook_paged_list
        headers = hook_paged_list.headers
      end
      hook_list
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
