require "omniauth/strategies/oauth2"

module OmniAuth
  module Strategies
    class Dropbox < OmniAuth::Strategies::OAuth2
      option :name, :dropbox

      BASE_URL = "https://www.dropbox.com"
      API_URL = "https://api.dropboxapi.com"

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

      uid { access_token.params["account_id"] }
      extra { raw_info }

      info do
        {
          uid: raw_info["account_id"],
          name: raw_info["name"]["display_name"],
          email: raw_info["email"]
        }
      end

      def raw_info
        @raw_info ||= access_token.post(
          "#{options[:client_options][:site]}/2/users/get_current_account",
          body: "null",
          headers: {"Content-Type": "application/json"}
        ).parsed
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
        full_host + script_name + callback_path
      end
    end
  end
end
