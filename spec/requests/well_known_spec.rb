require "rails_helper"

RSpec.describe "WellKnown", type: :request do
  let(:oidc_config) do
    {
      "issuer" => "http://oidc.local/realms/test",
      "authorization_endpoint" => "http://oidc.local/realms/test/protocol/openid-connect/auth",
      "token_endpoint" => "http://oidc.local/realms/test/protocol/openid-connect/token",
      "registration_endpoint" => "http://oidc.local/realms/test/clients-registrations/openid-connect",
      "response_types_supported" => ["code"],
      "code_challenge_methods_supported" => ["S256"],
      "grant_types_supported" => ["authorization_code"],
      "token_endpoint_auth_methods_supported" => ["client_secret_basic"],
      "jwks_uri" => "http://oidc.local/realms/test/protocol/openid-connect/certs"
    }
  end

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("OIDC_ISSUER").and_return("http://oidc.local/realms/test")
    fake_response = instance_double(Faraday::Response, body: oidc_config.to_json, success?: true)
    allow(Faraday).to receive(:get).and_return(fake_response)
  end

  it "returns OAuth metadata proxied from OIDC discovery" do
    get "/.well-known/oauth-authorization-server"

    expect(response).to have_http_status(:ok)
    json = response.parsed_body
    expect(json["issuer"]).to eq("http://oidc.local/realms/test")
    expect(json["authorization_endpoint"]).to include("/protocol/openid-connect/auth")
    expect(json["token_endpoint"]).to include("/protocol/openid-connect/token")
    expect(json).not_to have_key("jwks_uri")
  end

  it "returns JSON content type" do
    get "/.well-known/oauth-authorization-server"

    expect(response.content_type).to include("application/json")
  end
end
