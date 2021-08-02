require "redis"
require "mock_redis"
require_relative "../../../lib/kc/cache/redis_cache"
require_relative "./cache_base_spec"

RSpec.describe Kc::Cache::RedisCache do
  let(:cache) do
    ENV["MODE"] = "test"
    described_class.new(MockRedis.new)
  end

  it_behaves_like "CacheBase"

  describe "when initializing a wrong redis instance" do
    it "throws error" do
      expect do
        described_class.new(123)
      end.to raise_error(RuntimeError, "Kc::Cache::RedisCache requires a Redis instance")
    end
  end
end
