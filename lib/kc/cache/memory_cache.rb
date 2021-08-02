require_relative "./cache_base"

module Kc
  # this class is to cache an object in memory
  module Cache
    class MemoryCache < Kc::Cache::CacheBase
      def get(_key)
        return @value if @expire_at && Time.now.to_i < @expire_at
      end

      def set(key, value, ttl_seconds)
        @key = key
        @value = value
        @expire_at = Time.now.to_i + ttl_seconds
      end

      def clear
        @key = nil
        @value = nil
        @expire_at = nil
      end
    end
  end
end
