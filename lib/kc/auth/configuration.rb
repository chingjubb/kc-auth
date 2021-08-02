require "active_support/configurable"

module Kc
  module Auth
    class Configuration
      include ActiveSupport::Configurable
      config_accessor :auth_server_url
      config_accessor :realm_ids
      config_accessor :context_key
      config_accessor :skip_paths
      config_accessor :authorization
      config_accessor :additional_attributes
      config_accessor :token_expiration_tolerance_in_seconds
      config_accessor :public_key_cache_ttl
      config_accessor :logger
      config_accessor :log_attributes
      config_accessor :ca_certificate_path
      config_accessor :valid_iss

      def post_validation(&blk)
        @post_validation_blk = blk
      end

      def execute_validation(context)
        @post_validation_blk.present? && @post_validation_blk.call(context)
      rescue StandardError => e
        raise TokenError.post_validation_failed(context, e.message)
      end
    end
  end
end
