require "logger"
require "uri"
require "date"
require "redis"
require "active_support/core_ext/numeric/time"

require_relative "auth/configuration"
require_relative "auth/service"
require_relative "auth/middleware"
require_relative "auth/context"
require_relative "auth/client"
require_relative "common/http_client"
require_relative "common/token_error"
require_relative "common/helper"
require_relative "common/public_key_resolver"
require_relative "cache/cache_base"
require_relative "cache/redis_cache"
require_relative "cache/memory_cache"
require_relative "client/token_fetcher"

module Kc
  module Auth
    def self.configure
      yield @configuration ||= Kc::Auth::Configuration.new
      url = config.auth_server_url&.chomp("/")
      config.valid_iss = config.realm_ids&.map { |realm| url + Kc::Common::Helper::ISS_PREFIX_KEY + realm }
    end

    def self.config
      @configuration
    end

    def self.http_client
      @http_client ||= Kc::Common::HTTPClient.new(config)
    end

    def self.public_key_resolver
      @public_key_resolver ||= Kc::Common::PublicKeyResolver.from_configuration(http_client, config)
    end

    def self.service
      @service ||= Kc::Auth::Service.new(public_key_resolver)
    end

    def self.post_validation(context)
      config.execute_validation(context)
    end

    def self.logger
      config.logger
    end

    def self.load_configuration
      configure do |config|
        config.auth_server_url = nil
        config.realm_ids = nil
        config.context_key = "ctx"
        config.skip_paths = {}
        config.authorization = false
        config.additional_attributes = nil
        config.token_expiration_tolerance_in_seconds = 300
        config.public_key_cache_ttl = 86_400
        config.logger = ::Logger.new($stdout)
        config.log_attributes = {}
        config.ca_certificate_path = nil
      end
    end

    load_configuration
  end
end
