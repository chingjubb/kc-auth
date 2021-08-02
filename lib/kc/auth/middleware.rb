module Kc
  module Auth
    class Middleware
      def initialize(app)
        @app = app
      end

      def call(env)
        dup._call(env)
      end

      def _call(env)
        method = env["REQUEST_METHOD"]
        path = env["PATH_INFO"]
        query_string = env["QUERY_STRING"]
        if service.need_authentication?(method, path, env)
          logger.debug("Start authentication for #{method} : #{path}")
          raw_token = service.read_token(query_string, env)
          decoded_token = service.decode_and_verify(raw_token)
          ctx = Kc::Auth::Context.new(config, env, raw_token, decoded_token)
          Kc::Auth.post_validation(ctx)
          authentication_succeeded(env, ctx)
        else
          logger.debug("Skip authentication for #{method} : #{path}")
          @app.call(env)
        end
      rescue TokenError => e
        authentication_failed(e)
      end

      def authentication_failed(err)
        error_log = {
          message: err.message,
          reason: err.reason,
          original_error: err.original_error,
        }
        ctx = err.ctx
        if ctx
          error_log[:context] = {
            kyc_client_id: ctx.attributes[:kyc_client_id],
            azp: ctx.attributes[:azp],
            iss: ctx.attributes[:iss],
            sub: ctx.attributes[:sub],
            email: ctx.attributes[:email]
          }
        end
        logger.error(error_log)
        [401, { "Content-Type" => "application/json" }, [{ error: err.message }.to_json]]
      end

      def authentication_succeeded(env, ctx)
        env[config.context_key] = ctx
        @app.call(env)
      end

      def service
        Kc::Auth.service
      end

      def logger
        Kc::Auth.logger
      end

      def config
        Kc::Auth.config
      end
    end
  end
end
