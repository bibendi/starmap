module OidcConfig
  ENABLED = ENV["OIDC_CLIENT_ID"].present?
  REGISTRATION_ENABLED = ENV.fetch("REGISTRATION_ENABLED", "false") == "true"

  if ENABLED
    %w[OIDC_ISSUER OIDC_CLIENT_SECRET].each do |var|
      raise "#{var} is required when OIDC_CLIENT_ID is set" if ENV[var].blank?
    end
  end

  def self.issuer
    ENV["OIDC_ISSUER"]
  end

  def self.client_id
    ENV["OIDC_CLIENT_ID"]
  end

  def self.client_secret
    ENV["OIDC_CLIENT_SECRET"]
  end

  def self.redirect_uri
    ENV["OIDC_REDIRECT_URI"]
  end
end

OIDC_ENABLED = OidcConfig::ENABLED
REGISTRATION_ENABLED = OidcConfig::REGISTRATION_ENABLED
