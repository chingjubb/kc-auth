class TokenError < StandardError
  attr_reader :token, :reason, :original_error, :ctx

  def initialize(token, reason, message, original_error, ctx: nil)
    super(message)
    @token = token
    @reason = reason
    @original_error = original_error
    @ctx = ctx
  end

  def self.verification_failed(token, original_error)
    TokenError.new(token, :verification_failed, original_error, original_error)
  end

  def self.invalid_format(token, original_error)
    TokenError.new(token, :invalid_format, "Wrong JWT Format", original_error)
  end

  def self.no_token(token)
    TokenError.new(token, :no_token, "No JWT token provided", nil)
  end

  def self.expired(token)
    TokenError.new(token, :expired, "JWT token is expired", nil)
  end

  def self.invalid_realm(uri)
    TokenError.new(nil, :verification_failed, "Cannot verify the token from the given realm", uri)
  end

  def self.post_validation_failed(ctx, message = "Post validation failed")
    TokenError.new(nil, :post_validation_failed, message, message, ctx: ctx)
  end

  def self.unknown(_token)
    TokenError.new
  end
end
