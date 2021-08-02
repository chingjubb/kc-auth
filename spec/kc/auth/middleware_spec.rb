RSpec.describe Kc::Auth::Middleware do
  Kc::Auth.configure do |config|
    config.auth_server_url = "http://example.org"
    config.realm_ids = %w[happy-path-1 happy-path-2]
    config.public_key_cache_ttl = 86_400
    config.skip_paths = {
      get: [%r{^/not_protected}],
    }
  end

  let(:app)               { ->(env) { [200, env, "app"] } }
  let(:middleware)        { Kc::Auth::Middleware.new(app) }
  let(:rack_mock_request) { Rack::MockRequest.new(middleware) }
  let(:url)               { "/protected" }
  let(:need_token)        { true }
  let(:iss)               { "happy-path-1" }
  let(:global_token)      { nil }

  def make_request
    if need_token
      token = global_token || KeyHelper.create_token_by_iss(iss, "http://example.org")
      uri = Kc::Common::Helper.create_url_with_token(url, token)
    end
    rack_mock_request.get(uri || url)
  end

  before(:each) do
    @response = make_request
  end

  context "without auth token" do
    let(:need_token) { false }

    context "proctected path" do
      it "should return 401 error" do
        expect(@response.status).to eq 401
      end
    end

    context "non-protected path" do
      let(:url) { "/not_protected" }
      it "should skip auth checks" do
        expect(@response.status).to eq 200
      end
    end
  end

  context "with auth token" do
    context "with valid token" do
      it "should pass auth validation" do
        expect(@response.status).to eq 200
        expect(@response[Kc::Auth.config.context_key]).to be_present
      end
    end
    context "with invalid token" do
      let(:global_token) { "garbage_value" }
      it "should return 401 error" do
        expect(@response.status).to eq 401
      end
    end
    context "with non-whitelisted realm" do
      let(:iss) { "happy-path-3" }
      it "should return 401 error" do
        expect(@response.status).to eq 401
      end
    end

    context "with invalid realm" do
      let(:iss) { "sad-path" }
      it "should return 401 error" do
        expect(@response.status).to eq 401
      end
    end

    context "with post_validation" do
      Kc::Auth.config.post_validation do |ctx|
        val = 123
        ctx.set_attr(:logged_in_at, val)
        raise StandardError("Cannot validate this realm currently") if ctx.attributes[:iss].include? "happy-path-2"
      end

      it "should set custom attribute" do
        expect(@response.status).to eq 200
        ctx = @response[Kc::Auth.config.context_key]
        expect(ctx.attributes[:logged_in_at]).to eq(123)
      end

      context "raise error in custom validation" do
        let(:iss) { "happy-path-2" }
        it "should return 401 error" do
          expect(@response.status).to eq 401
          ctx = @response[Kc::Auth.config.context_key]
          expect(ctx).to be_nil
        end
      end
    end
  end
end
