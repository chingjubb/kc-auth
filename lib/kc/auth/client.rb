require_relative "../client/token_fetcher"
require_relative "../cache/memory_cache"
require_relative "../cache/cache_base"
require_relative "../cache/redis_cache"

CACHE_KEY_PREFIX = "KC_Auth_Client_AccessToken_CacheKey".freeze

module Kc
  # this class is for client to get an access token from keycloak server,
  # the client needs to provide the following information in the config object:
  # token_endpoint, client_id, client_secret, issuer_host, realm_id, (optional) cache
  # if token_endpoint is not provided, we will use issuer_host and realm_id to construct the endpoint
  # Usage:
  # config = {
  #   issuer_host: "https://test.xfers.com",
  #   realm_id: "the_realm",
  #   client_id: "foobar",
  #   client_secret: "1234",
  #   cache: Kc::Cache::RedisCache.new(RedisConnector.instance.redis), (cache is optional)
  # }
  # client = Kc::Auth::Client.new(config)
  # client.access_token
  #
  module Auth
    class Client
      def initialize(config)
        @issuer_host = config[:issuer_host]
        @realm_id = config[:realm_id]
        @token_endpoint = if @issuer_host && @realm_id
                            "#{@issuer_host}/auth/realms/#{@realm_id}/protocol/openid-connect/token"
                          else
                            config[:token_endpoint]
                          end
        @client_id = config[:client_id]
        @client_secret = config[:client_secret]
        @cache = config[:cache] || Kc::Cache::MemoryCache.new
        @cache_key = "#{CACHE_KEY_PREFIX}_#{@token_endpoint}_#{@client_id}"
        validate_config
      end

      def access_token
        token = @cache.get(@cache_key)
        return token unless token.nil?
        token, expire_in = Kc::Client::TokenFetcher.get(@token_endpoint, @client_id, @client_secret)
        @cache.set(@cache_key, token, expire_in - 30) # 30 second is buffer
        token
      end

      def revoke_token
        @cache.clear
      end

      private def validate_config
        raise "Config object should contain token_endpoint or issuer_host and realm_id" unless @token_endpoint || (@issuer_host && @realm_id)
        raise "issuer_host should start with https:// or http://" if @issuer_host && !@issuer_host.include?("http") # rubocop:disable Rails/NegateInclude
        raise "token_endpoint should start with https:// or http://" if @token_endpoint && !@token_endpoint.include?("http") # rubocop:disable Rails/NegateInclude
        raise "Config object should contain client_id and client_secret" if @client_id.nil? || @client_secret.nil?
        raise "Cache should implement Kc::Cache::CacheBase" unless @cache.is_a? Kc::Cache::CacheBase
      end
    end
  end
end
