# frozen_string_literal: true

class WellKnownController < ActionController::API
  METADATA_KEYS = %w[
    issuer authorization_endpoint token_endpoint
    registration_endpoint response_types_supported
    code_challenge_methods_supported grant_types_supported
    token_endpoint_auth_methods_supported
  ].freeze

  def oauth_authorization_server
    issuer = ENV.fetch("OIDC_ISSUER")
    config = fetch_oidc_config(issuer)
    render json: config.slice(*METADATA_KEYS)
  end

  def oauth_protected_resource
    render json: {
      resource: mcp_url,
      authorization_servers: [ENV.fetch("OIDC_ISSUER")],
      scopes_supported: [],
      bearer_methods_supported: ["header"],
      token_types_supported: ["bearer"]
    }
  end

  private

  def mcp_url
    "#{request.base_url}/mcp"
  end

  def fetch_oidc_config(issuer)
    response = Faraday.get("#{issuer}/.well-known/openid-configuration") { |req| req.options.timeout = 5 }
    JSON.parse(response.body)
  end
end
