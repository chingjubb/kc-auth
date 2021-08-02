RSpec.describe Kc::Common::PublicKeyResolver do
  Kc::Auth.configure do |config|
    config.auth_server_url = "http://example.org"
    config.public_key_cache_ttl = 86_400
  end

  let(:public_key_cache_ttl)  { 86_400 }
  let(:realm_id)              { "happy-path" }
  let(:resolver) { Kc::Auth.public_key_resolver }

  describe "#find_public_key" do
    context "when there is no public key in cache yet" do
      before(:each) do
        @public_key = resolver.find_public_keys(realm_id)
      end

      it "returns a valid public key" do
        expect(@public_key).to_not be_nil
      end
    end

    context "when there is already a public key in cache" do
      before(:each) do
        @first_public_key = resolver.find_public_keys(realm_id)
        @first_cached_public_key_retrieved_at = resolver.last_updated_at(realm_id)
      end

      context "and no need to refresh it" do
        before(:each) do
          @second_public_key = resolver.find_public_keys(realm_id)
          @second_cached_public_key_retrieved_at = resolver.last_updated_at(realm_id)
        end

        it "returns a valid public key" do
          expect(@second_public_key).to_not be_nil
        end

        it "does not refresh the public key" do
          expect(@second_public_key).to eq @first_public_key
        end

        it "does not refresh the public key retrieval time" do
          expect(@first_cached_public_key_retrieved_at).to eq @second_cached_public_key_retrieved_at
        end
      end

      context "and its TTL has expired" do
        before(:each) do
          Timecop.freeze(Time.now + public_key_cache_ttl + 10)
          @second_public_key = resolver.find_public_keys(realm_id)
          @second_cached_public_key_retrieved_at = resolver.last_updated_at(realm_id)
        end

        it "returns a valid public key" do
          expect(@second_public_key).to_not be_nil
        end

        it "refreshes the public key" do
          expect(@second_public_key).to_not eq @first_public_key
        end

        it "refreshes the public key retrieval time" do
          expect(@first_cached_public_key_retrieved_at).to_not eq @second_cached_public_key_retrieved_at
        end
      end
    end
  end

  describe "#fetch_remote_public_keys" do
    context "when the publey cannot be found" do
      let(:realm_id) { "sad-path" }

      it "should throw an error" do
        expect do
          resolver.find_public_keys(realm_id)
        end.to raise_error(TokenError, "Cannot verify the token from the given realm")
      end
    end
  end
end
