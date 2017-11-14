require 'logging-helper'
require 'httparty'
require 'json'
require 'uri'

module Github
  class Organizations
    include LoggingHelper::LogToTerminal
    include HTTParty
    default_params :output => 'json'
    format :json

    def initialize(username, password, base_url='https://api.github.com')
      @username = username
      @password = password
      @base_url = base_url
      @organizations = []
    end

    def member?(organization_name, user)
      get(
        "#{base_url}/orgs/#{organization_name}/memberships/#{user}",
        basic_auth:{
          username: username,
          password: password
        }
      ).code == 200
    end

    def add_memebers(organization_name, users)
      users.each{|user|
        add_member(organization_name, user) unless member?(organization_name, user)
      }
    end

    def add_member(organization_name, user, role='member')
      debug{"add_member(#{organization_name}, #{user}, #{role})"}
      put(
        "#{base_url}/orgs/#{organization_name}/memberships/#{user}",
        basic_auth:{
          username: username,
          password: password
        },
        body:{
          role: role
        }.to_json
      )
    end

    def organizations
      return @organizations unless @organizations.empty?
      organization_list = get(
        "#{base_url}/organizations",
        basic_auth:{
          username: username,
          password: password
        }
      )
      @organizations.concat organization_list
      headers = organization_list.headers
      while !headers['Link'].nil?
        next_page = headers['Link'].split(';')[0][/<(.*)>/, 1]

        break unless next_page =~ /\A#{URI::regexp(['http', 'https'])}\z/
        break if next_page.end_with?('page=1')
        debug {"next_page -> #{next_page}"}

        organization_list = get(
          next_page,
          basic_auth:{
            username: username,
            password: password
          }
        )

        @organizations.concat organization_list
        headers = organization_list.headers
      end
      @organizations
    end

    def members(organization_name, opts={})
      member_list = []
      member_paged_list = get(
        "#{base_url}/orgs/#{organization_name}/members",
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

    def exist?(name)
      organization = get(
        "#{base_url}/orgs/#{name}",
        basic_auth:{
          username: username,
          password: password
        }
      )
      organization.code == 200
    end

    def create(name, display_name, admin_user)
      options = {
        login: login,
        admin: admin,
        profile_name: display_name,
        accept: 'application/json'
      }

      post "admin/organizations", options
    end

    def hooks(organization_name)
      hook_list = []
      hook_paged_list = get(
        "#{base_url}/orgs/#{organization_name}/hooks",
        basic_auth:{
          username: username,
          password: password
        }
      )
      puts hook_paged_list.pretty_inspect
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
