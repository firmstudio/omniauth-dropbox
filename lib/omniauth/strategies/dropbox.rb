require "omniauth/strategies/oauth2"
require "net/http"
require "uri"
require "json"

module OmniAuth
  module Strategies
    class Dropbox < OmniAuth::Strategies::OAuth2
      option :name, :dropbox

      BASE_URL = "https://www.dropbox.com"
      API_URL = "https://api.dropbox.com"

      if OmniAuth.config.test_mode
        option :client_options, {
          authorize_url: "http://localhost:3000/v1/oauth/authorize",
          token_url: "http://localhost:3000/v1/oauth/token",
          site: "http://localhost:3000"
        }
      else
        option :client_options, {
          authorize_url: "#{BASE_URL}/oauth2/authorize",
          token_url: "#{API_URL}/oauth2/token",
          site: API_URL
        }
      end

      option :authorize_options, [
        :scope, :token_access_type, :force_reauthentication, :force_reapprove, :include_granted_scopes
      ]

      uid do
        access_token.token ? raw_info["account_id"] : nil
      end

      info do
        {
          "uid" => raw_info["account_id"],
          "name" => raw_info["name"]["display_name"],
          "email" => raw_info["email"]
        }
      end

      extra do
        {"raw_info" => raw_info}
      end

      def authorize_params
        super.tap do |params|
          params[:token_access_type] = "offline"
        end
      end

      def raw_info
        @raw_info ||= begin
          uri = URI.parse("https://api.dropbox.com/2/users/get_current_account")
          request = Net::HTTP::Post.new(uri)
          request.content_type = "application/json"
          request["Authorization"] = "Bearer #{access_token.token}"
          request.body = JSON.dump(nil)

          response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == "https") do |http|
            http.request(request)
          end

          JSON.parse(response.body)
        end
      end

      # Over-ride callback_url definition to maintain
      # compatability with omniauth-oauth2 >= 1.4.0 Dropbox will verify that the
      # redirect_uri provided in the token request matches the one used for
      # the authorize request, and using the query string will cause
      # redirect_uri mismatch errors.
      # OmniAuth issue: https://github.com/omniauth/omniauth-oauth2/issues/93
      # Similar: https://github.com/icoretech/omniauth-dropbox2/pull/2/files
      # https://github.com/nitanshu/omniauth-dropbox-business-api2/blob/master/lib/omniauth/strategies/dropbox_oauth2.rb
      # See: https://github.com/intridea/omniauth-oauth2/issues/81
      def callback_url
        options[:callback_url] || full_host + script_name + callback_path
      end
    end
  end
end
