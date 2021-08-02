class KeyHelper
  KEYS = {
    "happy-path-1" => OpenSSL::PKey::RSA.generate(1024),
    "happy-path-2" => OpenSSL::PKey::RSA.generate(1024),
    "happy-path-3" => OpenSSL::PKey::RSA.generate(1024),
  }.freeze

  def self.generate_claim(iss, expiration_date, host = "")
    {
      iss: host + Kc::Common::Helper::ISS_PREFIX_KEY + (iss || "happy-path-1"),
      exp: expiration_date&.to_i,
      nbf: Time.new(2014, 1, 1).to_i,
    }
  end

  def self.create_token(private_key, expiration_date, algorithm, iss: nil, host: "")
    claim = generate_claim(iss, expiration_date, host)
    jws = JWT.encode claim, private_key, algorithm
    jws.to_s
  end

  def self.create_token_by_iss(iss, host)
    private_key = KEYS[iss] || OpenSSL::PKey::RSA.generate(1024)
    claim = generate_claim(iss, 1.week.from_now, host)
    jws = JWT.encode claim, private_key, "RS256"
    jws.to_s
  end
end
