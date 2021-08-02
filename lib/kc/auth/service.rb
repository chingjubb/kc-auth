require "jwt"

module Kc
  module Auth
    class Service
      JWT_ALGORITHM = %w[RS256 RS512].freeze

      def initialize(key_resolver)
        @key_resolver = key_resolver
        @skip_paths = config.skip_paths
        @logger = config.logger
        @token_expiration_tolerance_in_seconds = config.token_expiration_tolerance_in_seconds
      end

      def decode_and_verify(token)
        if token.nil? || token&.empty?
          raise TokenError.no_token(token)
        else
          decoded_token = JWT.decode(token, nil, true, { iss: config.valid_iss, verify_iss: true, algorithms: JWT_ALGORITHM }) do |_header, payload|
            realm_id = Kc::Common::Helper.get_realm_from_token_payload(payload)
            @key_resolver.find_public_keys(realm_id)
          end
          decoded_token = decoded_token[0]
          decoded_token = decoded_token&.transform_keys(&:to_sym)
          if expired?(decoded_token)
            raise TokenError.expired(token)
          else
            decoded_token
          end
        end
      rescue JWT::JWKError
        raise TokenError.invalid_format(token, e)
      rescue JWT::ExpiredSignature
        raise TokenError.expired(token)
      rescue JWT::VerificationError, JWT::DecodeError => e
        raise TokenError.verification_failed(token, e)
      end

      def read_token(uri, headers)
        Kc::Common::Helper.get_access_token(uri, headers)
      end

      def need_authentication?(method, path, headers)
        !should_skip?(method, path) && !is_preflight?(method, headers)
      end

      private def should_skip?(method, path)
        method_symbol = method&.downcase&.to_sym
        skip_paths = @skip_paths[method_symbol]
        !skip_paths.nil? && !skip_paths.empty? && !skip_paths.find_index { |skip_path| skip_path.match(path) }.nil?
      end

      private def is_preflight?(method, headers)
        method_symbol = method&.downcase&.to_sym
        method_symbol == :options && !headers["HTTP_ACCESS_CONTROL_REQUEST_METHOD"].nil?
      end

      private def expired?(token)
        token_expiration = Time.at(token[:exp].to_i)
        token_expiration < Time.now + @token_expiration_tolerance_in_seconds
      end

      def config
        Kc::Auth.config
      end
    end
  end
end
