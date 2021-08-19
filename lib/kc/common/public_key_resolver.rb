require "jwt"

module Kc
  module Common
    class PublicKeyResolver
      CERT_PATH_KEY = "protocol/openid-connect/certs".freeze

      def initialize(http_client, public_key_cache_ttl)
        @http_client = http_client
        @public_key_cache_ttl = public_key_cache_ttl
        @cached_public_keys = {}
      end

      def self.from_configuration(http_client, configuration)
        PublicKeyResolver.new(http_client, configuration.public_key_cache_ttl)
      end

      def find_public_keys(realm_id)
        if public_keys_expired?(realm_id)
          @cached_public_keys[realm_id] = {
            keys: fetch_remote_public_keys(realm_id),
            updated_at: Time.now,
          }
        end
        @cached_public_keys[realm_id][:keys]
      end

      def last_updated_at(realm_id)
        @cached_public_keys[realm_id].present? && @cached_public_keys[realm_id][:updated_at]
      end

      def fetch_remote_public_keys(realm_id)
        keys = @http_client.get(realm_id, CERT_PATH_KEY)[:keys][0]
        JWT::JWK::RSA.import(keys).public_key
      end

      private def public_keys_expired?(realm_id)
        @cached_public_keys[realm_id].nil? || Time.now > (last_updated_at(realm_id) + @public_key_cache_ttl)
      end
    end
  end
end
