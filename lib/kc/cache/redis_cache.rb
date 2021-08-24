require_relative "./cache_base"
require "redis"
require "mock_redis"

module Kc
  # this class is to cache an object in Redis
  module Cache
    class RedisCache < Kc::Cache::CacheBase
      def initialize(redis)
        super()
        # raise "Kc::Cache::RedisCache requires a Redis instance" unless redis.is_a?(Redis) || (redis.is_a?(MockRedis) && ENV["MODE"] == "test")
        @redis = redis # redis is an object such as RedisConnector.instance.redis
      end

      def get(key)
        return @redis.get(key) if @expire_at && Time.now.to_i < @expire_at
      end

      def set(key, value, ttl_seconds)
        @key = key
        @expire_at = Time.now.to_i + ttl_seconds
        @redis.set(@key, value)
      end

      def clear
        @redis.set(@key, nil)
        @key = nil
        @expire_at = nil
      end
    end
  end
end
