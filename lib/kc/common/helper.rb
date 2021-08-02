module Kc
  module Common
    class Helper
      QUERY_STRING_TOKEN_KEY = "authorizationToken".freeze
      ISS_PREFIX_KEY = "/auth/realms/".freeze

      def self.create_url_with_token(uri, token)
        uri = URI(uri)
        params = URI.decode_www_form(uri.query || "").reject { |query_string| query_string.first == QUERY_STRING_TOKEN_KEY }
        params << [QUERY_STRING_TOKEN_KEY, token]
        uri.query = URI.encode_www_form(params)
        uri.to_s
      end

      def self.get_access_token(query_string, headers)
        read_token_from_query_string(query_string) || read_token_from_headers(headers)
      end

      def self.get_realm_from_token_payload(payload)
        iss = payload["iss"]
        iss.present? && (iss [/#{ISS_PREFIX_KEY}(.+)/, 1] || iss)
      end

      def self.read_token_from_query_string(query_string)
        query = URI.decode_www_form(query_string)
        query_string_token = query.detect { |param| param.first == QUERY_STRING_TOKEN_KEY }
        query_string_token&.last
      end

      def self.read_token_from_headers(headers)
        headers["HTTP_AUTHORIZATION"]&.gsub(/^Bearer /, "") || ""
      end
    end
  end
end
