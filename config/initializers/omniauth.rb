if OIDC_ENABLED
  issuer = ENV["OIDC_ISSUER"]

  SWD.url_builder = URI::HTTP if issuer.start_with?("http://")

  Rails.application.config.middleware.use OmniAuth::Builder do
    provider :openid_connect, {
      name: :oidc,
      issuer: issuer,
      discovery: true,
      scope: [:openid, :email, :profile],
      response_type: :code,
      client_options: {
        identifier: ENV["OIDC_CLIENT_ID"],
        secret: ENV["OIDC_CLIENT_SECRET"],
        redirect_uri: ENV.fetch("OIDC_REDIRECT_URI", nil)
      }
    }
  end
end
