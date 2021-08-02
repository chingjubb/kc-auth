require "active_support/time"
require "active_support/testing/time_helpers"
require_relative "../../../lib/kc/cache/cache_base"

# To use these shared examples, the describe_class needs to init a 'cache' instance
RSpec.shared_examples "CacheBase" do
  include ActiveSupport::Testing::TimeHelpers

  describe "#set and #get" do
    it "puts the value in cache and retreives it" do
      cache.set("key", "hello world", 60)
      expect(cache.get("key")).to eq("hello world")
    end
  end

  describe "#clear" do
    it "clears the cache" do
      cache.set("key", "hello world", 60)
      cache.clear
      expect(cache.get("key")).to be_nil
    end
  end

  describe "when value is expired" do
    it "returns nil" do
      cache.set("key", "hello world", 60)
      travel_to 61.seconds.from_now do
        expect(cache.get("key")).to be_nil
      end
    end
  end

  it "is a CacheBase" do
    expect(cache.is_a?(Kc::Cache::CacheBase)).to eq(true)
  end
end
