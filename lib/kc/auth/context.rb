module Kc
  module Auth
    class Context
      attr_reader :env, :raw_token, :token, :attributes
      attr_accessor :props

      def initialize(config, env, raw_token, claims)
        @config = config
        @env = env
        @raw_token = raw_token
        @props = {}
        @attributes = {}.merge!(claims).freeze
      end

      def set_attr(key, value)
        if @attributes[key].nil?
          dup_obj = @attributes.dup
          dup_obj[key] = value
          @attributes = dup_obj.freeze
        end
      end
    end
  end
end
