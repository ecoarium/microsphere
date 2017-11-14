require 'logging-helper'
require 'octokit'
require 'httparty'
require 'nokogiri'

module Github
  class Defender
    include LoggingHelper::LogToTerminal
    include HTTParty

    class << self
      alias :original_get :get
      def get(*args)
        request_wrapper(:original_get, *args)
      end

      alias :original_post :post
      def post(*args)
        request_wrapper(:original_post, *args)
      end

      def request_wrapper(method_symbol, path, options={})
        opts_headers = {
          headers: {
            'Cookie' => @cookies
          }
        }
        options.merge!(opts_headers) unless @cookies.nil?
        response = send(method_symbol, path, options)

        raise %/
failed http response code: #{response.code}
path: #{path}

options:
#{options.pretty_inspect}

headers:
#{response.headers}

      / unless response.code == 200
        @cookies = response.headers['Set-Cookie']
        response
      end
    end
    attr_reader :github_url, :api_endpoint
    attr_reader :user_name, :password

    def initialize(user_name, password, opts={})
      @user_name = user_name
      @password = password

      if @github_url.nil?
        @github_url = $WORKSPACE_SETTINGS[:git][:repo][:base][:url]
      else
        @github_url = opts.delete(:github_url)
      end

      @api_endpoint = "#{github_url}/api/v3/"

      configure_octokit
    end

    def configure_octokit
      Octokit.configure do |c|
        c.api_endpoint = api_endpoint
        c.web_endpoint = github_url
        c.login = user_name
        c.password = password
        c.connection_options[:ssl] = { :verify => false }
      end

      debug {
        require 'logger'
        logger = ::Logger.new(STDOUT)
        logger.level = ::Logger::DEBUG

        stack = Faraday::RackBuilder.new do |builder|
          builder.response :logger, logger, { :bodies => true }
          builder.use Octokit::Response::RaiseError
          builder.adapter Faraday.default_adapter
        end
        Octokit.middleware = stack
        nil
      }
      Octokit.auto_paginate = true
    end

    def client
      return @client unless @client.nil?
      configure_octokit
      @client = Octokit::Client.new
    end

    def create_status(repo)
      default_info = {
        :context => 'lock_branch'
      }
      default_state = 'failure'
      default_sha = client.commits(repo).last.sha
      client.create_status(repo, default_sha, default_state, default_info)
    end

    def create_session()
      response = self.class.get("#{github_url}/login")
      page = Nokogiri::HTML(response.body)
      authenticity_token = page.at_xpath('//*[@id="login"]/form/div/input[@name="authenticity_token"]')['value']

      response = self.class.post(
        "#{github_url}/session",
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
        },
        body: {
          authenticity_token: authenticity_token,
          login: user_name,
          password: password
        }
      )
    end

    def get_branches(repo)
      client.branches(repo)
    end

    def protect_branch(repo, branch)

      response = self.class.get("#{github_url}/#{repo}/settings/branches/#{branch}",)

      page = Nokogiri::HTML(response.body)
      authenticity_token = page.at_xpath('//*[@id="branches_bucket"]/form/div/input[@name="authenticity_token"]')['value']

      response = self.class.post(
        "#{github_url}/#{repo}/settings/branches/#{branch}",
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
        },
        body: {
          authenticity_token: authenticity_token,
          _method: 'put',
          secure: 'on',
          has_required_statuses: 'on',
          enforce_for_admins: 'on',
          contexts: "lock_branch"
        }
      )
    end

    def protect_all_branches(repo)
      get_branches(repo).each do |branch|
        puts "locking: #{branch.name}"
        protect_branch(repo, branch.name)
      end
    end

    def remove_branch_protection(repo, branch)
      response = self.class.get("#{github_url}/#{repo}/settings/branches/#{branch}",)

      page = Nokogiri::HTML(response.body)
      authenticity_token = page.at_xpath('//*[@id="branches_bucket"]/form/div/input[@name="authenticity_token"]')['value']

      response = self.class.post(
        "#{github_url}/#{repo}/settings/branches/#{branch}",
        headers: {
          'Content-Type' => 'application/x-www-form-urlencoded',
        },
        body: {
          authenticity_token: authenticity_token,
          _method: 'put'
        }
      )
    end

  end
end
