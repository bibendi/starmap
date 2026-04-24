# frozen_string_literal: true

Warden::Strategies.add(:bearer_token) do
  def valid?
    request.authorization.to_s.start_with?("Bearer ")
  end

  def authenticate!
    token = request.authorization.sub("Bearer ", "")
    user = OidcTokenValidator.call(token: token)
    request.env["devise.skip_trackable"] = true
    success!(user)
  rescue OidcTokenValidator::InvalidToken,
    OidcTokenValidator::TokenExpired,
    OidcTokenValidator::InvalidIssuer => e
    Rails.logger.warn("[MCP] Auth failed: #{e.message}")
    fail!(e.message)
  end

  def store?
    false
  end
end
