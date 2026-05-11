# frozen_string_literal: true

Warden::Strategies.add(:api_client_token) do
  def valid?
    request.authorization.to_s.start_with?("Bearer ")
  end

  def authenticate!
    token = request.authorization.sub("Bearer ", "")
    identity = OidcTokenValidator.call(token: token)
    return unless identity.is_a?(ApiClient)

    request.env["devise.skip_trackable"] = true
    success!(identity)
  rescue OidcTokenValidator::InvalidToken,
    OidcTokenValidator::TokenExpired,
    OidcTokenValidator::InvalidIssuer => e
    Rails.logger.warn("[ApiClient] Auth failed: #{e.class} - #{e.message}")
    fail!(e.message)
  end

  def store?
    false
  end
end
