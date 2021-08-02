module Kc
  # this class is to cache an object
  # Implemetations are MemoryCache and RedisCache
  module Cache
    class CacheBase
      def get(_key)
        raise "Not implemented"
      end

      def set(_key, _value, _ttl_seconds)
        raise "Not implemented"
      end

      def clear
        raise "Not implemented"
      end
    end
  end
end
