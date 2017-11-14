require 'logging-helper'
require 'httparty'
require 'json'
require 'uri'

module Github
  class Users
    include LoggingHelper::LogToTerminal
    include HTTParty
    default_params :output => 'json'
    format :json

    def initialize(username, password, base_url='https://api.github.com')
      @username = username
      @password = password
      @base_url = base_url
      @users = []
    end

    def users
      return @users unless @users.empty?
      user_list = get(
        "#{base_url}/users",
        basic_auth:{
          username: username,
          password: password
        }
      )
      @users.concat user_list
      headers = user_list.headers
      while !headers['Link'].nil?
        next_page = headers['Link'].split(';')[0][/<(.*)>/, 1]

        break unless next_page =~ /\A#{URI::regexp(['http', 'https'])}\z/
        break if next_page.end_with?('page=1')
        debug {"next_page -> #{next_page}"}

        user_list = get(
          next_page,
          basic_auth:{
            username: username,
            password: password
          }
        )

        @users.concat user_list
        headers = user_list.headers
      end
      @users
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
