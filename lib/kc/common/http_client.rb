require "net/http"

module Kc
  module Common
    class HTTPClient
      def initialize(configuration)
        @server_url = configuration.auth_server_url
      end

      def get(realm_id, path)
        uri = build_uri(realm_id, path)
        response = Net::HTTP.get_response(uri)
        raise TokenError.invalid_realm(uri) unless response.code == "200"

        JSON.parse(response.body, symbolize_names: true)
      end

      private def build_uri(realm_id, path)
        string_uri = File.join(@server_url, "auth", "realms", realm_id, path)
        URI(string_uri)
      end
    end
  end
end
