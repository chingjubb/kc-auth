require "httparty"
require_relative "../../../lib/kc/client/token_fetcher"
require_relative "../../support/requests_stub"

RSpec.describe Kc::Client::TokenFetcher do
  describe "#get" do
    it "sends an HTTP request" do
      token_endpoint = "https://test.xfers.com/auth"
      stub_access_token_request(token_endpoint, "access_token123", 3600)
      expect(described_class.get(token_endpoint, "client_id", "client_secret")).to eq(["access_token123", 3600])
      assert_requested(:post, token_endpoint, times: 1)
    end

    it "throws error if getting error message" do
      token_endpoint = "https://test.xfers.com/auth"
      stub_failed_token_request(token_endpoint, "Invalid client credentials")
      expect do
        described_class.get(token_endpoint, "client_id", "client_secret")
      end.to raise_error(RuntimeError, "Invalid client credentials")
    end

    it "throws error if request fails" do
      token_endpoint = "https://test.xfers.com/auth"
      allow(HTTParty).to receive(:post).and_raise("Bad gateway error!")
      expect do
        described_class.get(token_endpoint, "client_id", "client_secret")
      end.to raise_error(RuntimeError, "Bad gateway error!")
    end
  end
end
