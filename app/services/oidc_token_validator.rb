# frozen_string_literal: true

class OidcTokenValidator
  JWKS_TTL = 1.hour
  DISCOVERY_TTL = 24.hours
  FARADAY_TIMEOUT = 5

  TokenExpired = Class.new(StandardError)
  InvalidIssuer = Class.new(StandardError)
  InvalidToken = Class.new(StandardError)

  def self.call(token:)
    new.call(token: token)
  end

  def call(token:)
    raise InvalidToken, "Token is blank" if token.blank?

    jwt = decode_jwt(token)
    verify_claims!(jwt)
    resolve_identity!(jwt)
  end

  private

  def resolve_identity!(jwt)
    return find_user!(jwt[:email]) if jwt[:email].present?
    raise InvalidToken, "Unrecognized token type: missing email and azp claims" if jwt[:azp].blank?

    find_api_client!(jwt[:azp])
  end

  def find_user!(email)
    User.find_by(email: email) || raise(InvalidToken, "No user found for email from token")
  end

  def find_api_client!(azp)
    client = ApiClient.enabled.find_by(oidc_client_id: azp)
    raise InvalidToken, "No API client found" unless client
    client
  end

  def decode_jwt(token)
    kid = extract_kid(token)
    raise InvalidToken, "Token missing key ID" unless kid

    public_key = fetch_jwks[kid]
    raise InvalidToken, "Signing key not found" unless public_key

    JSON::JWT.decode_compact_serialized(token, public_key, :RS256)
  rescue JSON::JWT::VerificationFailed, JSON::JWT::InvalidFormat => e
    raise InvalidToken, "Token verification failed: #{e.message}"
  end

  def extract_kid(token)
    header_segment = token.split(".", 2).first
    JSON.parse(Base64.urlsafe_decode64(header_segment))["kid"]
  rescue JSON::ParserError, ArgumentError
    nil
  end

  def verify_claims!(jwt)
    raise TokenExpired, "Token has expired" if jwt[:exp].present? && Time.zone.at(jwt[:exp]) < Time.current
    raise InvalidIssuer, "Invalid issuer" if jwt[:iss] != issuer
    return if jwt[:aud].blank?
    return if Array(jwt[:aud]).include?(client_id)
    return if jwt[:email].blank? && jwt[:azp].present?

    raise InvalidToken, "Invalid audience: expected #{client_id}, got #{Array(jwt[:aud]).join(", ")}"
  end

  def fetch_jwks
    Rails.cache.fetch("oidc_jwks", expires_in: JWKS_TTL) do
      JSON::JWK::Set.new(fetch_json(jwks_uri))
    end
  end

  def jwks_uri
    Rails.cache.fetch("oidc_jwks_uri", expires_in: DISCOVERY_TTL) do
      config = fetch_json("#{issuer}/.well-known/openid-configuration")
      config.fetch("jwks_uri")
    end
  end

  def fetch_json(url)
    response = Faraday.get(url) { |req| req.options.timeout = FARADAY_TIMEOUT }
    raise InvalidToken, "OIDC provider returned HTTP #{response.status}" unless response.success?

    JSON.parse(response.body)
  rescue Faraday::Error => e
    raise InvalidToken, "OIDC provider unavailable: #{e.message}"
  rescue JSON::ParserError
    raise InvalidToken, "Invalid response from OIDC provider"
  end

  def issuer
    OidcConfig.issuer
  end

  def client_id
    OidcConfig.client_id
  end
end
