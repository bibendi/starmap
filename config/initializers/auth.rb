OIDC_ENABLED = ENV["OIDC_CLIENT_ID"].present?
REGISTRATION_ENABLED = ENV.fetch("REGISTRATION_ENABLED", "false") == "true"

if OIDC_ENABLED
  %w[OIDC_ISSUER OIDC_CLIENT_SECRET].each do |var|
    raise "#{var} is required when OIDC_CLIENT_ID is set" if ENV[var].blank?
  end
end
