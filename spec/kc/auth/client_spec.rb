require "active_support/time"
require "active_support/testing/time_helpers"
require_relative "../../../lib/kc/auth/client"
require_relative "../../../lib/kc/cache/memory_cache"
require_relative "../../../lib/kc/cache/cache_base"
require_relative "../../../lib/kc/cache/redis_cache"
require_relative "../../support/requests_stub"

RSpec.describe Kc::Auth::Client do
  include ActiveSupport::Testing::TimeHelpers
  let(:token_endpoint) { "https://test.xfers.com/auth" }
  let(:config) do
    {
      token_endpoint: token_endpoint,
      client_id: "client_id",
      client_secret: "client_secret"
    }
  end
  let(:client) { described_class.new(config) }

  describe "#access_token" do
    it "gets an access_token" do
      stub_access_token_request(token_endpoint, "token", 3600)
      expect(client.access_token).to eq("token")
    end

    it "puts the token in cache with a ttl" do
      stub_access_token_request(token_endpoint, "token", 3600)
      expect_any_instance_of(Kc::Cache::MemoryCache).to receive(:set)
        .with("KC_Auth_Client_AccessToken_CacheKey_https://test.xfers.com/auth_client_id", "token", 3570)
      client.access_token
    end

    it "gets the token from cache for subsequent call within expiration time" do
      stub_access_token_request(token_endpoint, "token", 3600)
      client.access_token
      assert_requested(:post, token_endpoint, times: 1)
      expect_any_instance_of(Kc::Cache::MemoryCache).to receive(:get).exactly(3).times
      travel_to 3560.seconds.from_now do
        client.access_token
        client.access_token
        client.access_token
      end
    end
  end

  describe "#revoke_token" do
    it "clears the token in cache" do
      stub_access_token_request(token_endpoint, "token", 3600)
      client.access_token
      expect_any_instance_of(Kc::Cache::MemoryCache).to receive(:clear)
      client.revoke_token
    end

    it "clears the token in cache and gets a new token in subsequent call" do
      stub_access_token_request(token_endpoint, "token", 3600)
      client.access_token
      assert_requested(:post, token_endpoint, times: 1)
      client.revoke_token
      stub_access_token_request(token_endpoint, "new_token", 3600)
      expect(client.access_token).to eq("new_token")
      assert_requested(:post, token_endpoint, times: 2)
    end
  end

  describe "when token is expired" do
    it "gets a new token" do
      stub_access_token_request(token_endpoint, "token", 3600)
      expect(client.access_token).to eq("token")
      stub_access_token_request(token_endpoint, "new_token", 3600)
      travel_to 3570.seconds.from_now do
        expect(client.access_token).to eq("new_token")
        assert_requested(:post, token_endpoint, times: 2)
      end
    end
  end

  describe "when config is missing realm_id" do
    it "throws error" do
      config2 = { issuer_host: "http://test.xfers.com", client_id: "client_id", client_secret: "client_secret" }
      expect do
        described_class.new(config2)
      end.to raise_error(RuntimeError, "Config object should contain token_endpoint or issuer_host and realm_id")
    end
  end

  describe "when config is missing issuer_host" do
    it "throws error" do
      config2 = { realm_id: "realm_id", client_id: "client_id", client_secret: "client_secret" }
      expect do
        described_class.new(config2)
      end.to raise_error(RuntimeError, "Config object should contain token_endpoint or issuer_host and realm_id")
    end

    it "issuer_host should start with https or http" do
      config2 = { issuer_host: "test.xfers.com", realm_id: "realm_id", client_id: "client_id", client_secret: "client_secret" }
      expect do
        described_class.new(config2)
      end.to raise_error(RuntimeError, "issuer_host should start with https:// or http://")
    end
  end

  describe "when config is missing token_endpoint" do
    it "throws error" do
      config2 = { client_id: "client_id", client_secret: "client_secret" }
      expect do
        described_class.new(config2)
      end.to raise_error(RuntimeError, "Config object should contain token_endpoint or issuer_host and realm_id")
    end

    it "token_endpoint should start with https or http" do
      config2 = { token_endpoint: "test.xfers.com", client_id: "client_id", client_secret: "client_secret" }
      expect do
        described_class.new(config2)
      end.to raise_error(RuntimeError, "token_endpoint should start with https:// or http://")
    end
  end

  describe "when config is missing client_id" do
    it "throws error" do
      config2 = { token_endpoint: "http://test.xfers.com", client_secret: "client_secret" }
      expect do
        described_class.new(config2)
      end.to raise_error(RuntimeError, "Config object should contain client_id and client_secret")
    end
  end

  describe "when config is missing client_secret" do
    it "throws error" do
      config2 = { token_endpoint: "https://test.xfers.com", client_id: "client_id" }
      expect do
        described_class.new(config2)
      end.to raise_error(RuntimeError, "Config object should contain client_id and client_secret")
    end
  end

  describe "when config has a cache object but not the right one" do
    it "throws error" do
      config2 = { cache: "cache", issuer_host: "http://test.xfers.com", client_id: "client_id", client_secret: "client_secret", realm_id: "realm_id" }
      expect do
        described_class.new(config2)
      end.to raise_error(RuntimeError, "Cache should implement Kc::Cache::CacheBase")
    end
  end

  describe "When specifying a RedisCache in config" do
    it "can work, too" do
      ENV["MODE"] = "test"
      config2 = {
        token_endpoint: token_endpoint,
        client_id: "client_id",
        client_secret: "client_secret",
        cache: Kc::Cache::RedisCache.new(MockRedis.new)
      }
      client2 = described_class.new(config2)
      stub_access_token_request(token_endpoint, "token", 3600)
      expect_any_instance_of(Kc::Cache::RedisCache).to receive(:set)
        .with("KC_Auth_Client_AccessToken_CacheKey_https://test.xfers.com/auth_client_id", "token", 3570)
      expect(client2.access_token).to eq("token")
    end
  end
end
