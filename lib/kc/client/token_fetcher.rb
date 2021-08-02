require "httparty"

module Kc
  # this class is to make http request to get an access token from keycloak server
  module Client
    class TokenFetcher
      include HTTParty

      def self.get(token_endpoint, client_id, client_secret)
        header = {
          Authorization: "Basic #{Base64.strict_encode64("#{client_id}:#{client_secret}")}",
          Accept: "application/json",
          "Content-Type": "application/x-www-form-urlencoded"
        }
        body = { grant_type: "client_credentials" }

        response = HTTParty.post(token_endpoint, headers: header, body: body)

        if response.code == 200
          access_token = response["access_token"] || response[:access_token]
          expires_in = response["expires_in"] || response[:expires_in] || 0 # e.g. 3600 (seconds)
          [access_token, expires_in]
        else
          error = response["error_description"] || response[:error_description]
          raise error
        end
      end
    end
  end
end
