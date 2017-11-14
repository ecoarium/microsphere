require 'octokit/response/raise_error'
require 'logging-helper'

module Octokit
  module Response
    class RaiseError < Faraday::Response::Middleware
      include LoggingHelper::LogToTerminal

      private

      def on_complete(response)
        if error = Octokit::Error.from_response(response)
          raise "#{error}
response error:
#{response.pretty_inspect}

"
        else
          debug "
response:
#{response.pretty_inspect}

"
        end
      end
    end
  end
end
