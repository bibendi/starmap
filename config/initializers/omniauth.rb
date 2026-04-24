if OIDC_ENABLED
  SWD.url_builder = URI::HTTP if OidcConfig.issuer.start_with?("http://")

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :openid_connect, {
      name: :oidc,
      issuer: OidcConfig.issuer,
      discovery: true,
      scope: [:openid, :email, :profile],
      response_type: :code,
      client_options: {
        identifier: OidcConfig.client_id,
        secret: OidcConfig.client_secret,
        redirect_uri: OidcConfig.redirect_uri
      }
    }
  end
end
