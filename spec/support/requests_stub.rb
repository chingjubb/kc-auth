require "webmock/rspec"

RSpec.configure do |config|
  certs_path = Kc::Common::PublicKeyResolver::CERT_PATH_KEY
  config.before do
    stub_request(:get, %r{.*/happy-path(.*)/#{certs_path}})
      .with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" })
      .to_return do |request|
        url = request.uri.request_uri
        realm_id = url [%r{#{Kc::Common::Helper::ISS_PREFIX_KEY}(.+)/#{certs_path}}, 1]
        priv_key = KeyHelper::KEYS[realm_id] || OpenSSL::PKey::RSA.generate(1024)
        {
          status: 200,
          body: JSON.generate({ keys: [JWT::JWK.new(priv_key).export] }),
          headers: {},
        }
      end

    stub_request(:get, %r{.*/sad-path/#{certs_path}})
      .with(headers: { "Accept" => "*/*", "User-Agent" => "Ruby" })
      .to_return(
        status: 404,
        body: JSON.generate({ msg: "Could not find the realm" }),
        headers: {},
      )
  end
end

def stub_access_token_request(token_endpoint, access_token, expires_in)
  stub_request(:post, token_endpoint)
    .with(
      body: { "grant_type" => "client_credentials" },
      headers: {
        "Accept" => "application/json",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Authorization" => "Basic Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ=",
        "Content-Type" => "application/x-www-form-urlencoded",
        "User-Agent" => "Ruby"
      }
    )
    .to_return(status: 200,
      body: { "access_token" => access_token, "expires_in" => expires_in }.to_json,
      headers: { content_type: "application/json" })
end

def stub_failed_token_request(token_endpoint, error_message)
  stub_request(:post, token_endpoint)
    .with(
      body: { "grant_type" => "client_credentials" },
      headers: {
        "Accept" => "application/json",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "Authorization" => "Basic Y2xpZW50X2lkOmNsaWVudF9zZWNyZXQ=",
        "Content-Type" => "application/x-www-form-urlencoded",
        "User-Agent" => "Ruby"
      }
    )
    .to_return(status: 400,
      body: { "error_description" => error_message }.to_json,
      headers: { content_type: "application/json" })
end
