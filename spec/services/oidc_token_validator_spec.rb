require "rails_helper"

RSpec.describe OidcTokenValidator, type: :service do
  let_it_be(:user) { create(:user, email: "test@example.com") }

  let(:issuer) { "http://oidc.local/realms/test" }
  let(:client_id) { "starmap" }
  let(:validator) { described_class.new }
  let(:private_key) { OpenSSL::PKey::RSA.new(2048) }
  let(:jwk) { JSON::JWK.new(private_key).tap { |j| j[:kid] = "test-kid" } }

  before do
    allow(OidcConfig).to receive_messages(issuer: issuer, client_id: client_id)
    allow(Rails.cache).to receive(:fetch).with("oidc_jwks", expires_in: described_class::JWKS_TTL).and_return(JSON::JWK::Set.new("keys" => [jwk]))
  end

  def sign_jwt(payload)
    JSON::JWT.new(payload).sign(jwk, :RS256).to_s
  end

  def valid_claims(overrides = {})
    {email: user.email, iss: issuer, aud: client_id, exp: 1.hour.from_now.to_i}.merge(overrides)
  end

  describe ".call" do
    it "delegates to instance" do
      instance = instance_double(described_class)
      allow(described_class).to receive(:new).and_return(instance)
      allow(instance).to receive(:call).with(token: "abc").and_return(user)

      expect(described_class.call(token: "abc")).to eq(user)
    end
  end

  describe "#call" do
    context "when token is blank" do
      it "raises InvalidToken" do
        expect { validator.call(token: "") }.to raise_error(OidcTokenValidator::InvalidToken, /blank/)
      end
    end

    context "when JWT has email (User token)" do
      it "returns user when all claims match" do
        expect(validator.call(token: sign_jwt(valid_claims))).to eq(user)
      end

      it "raises InvalidToken when user not found" do
        expect { validator.call(token: sign_jwt(valid_claims(email: "unknown@example.com"))) }.to raise_error(OidcTokenValidator::InvalidToken, /No user found/)
      end

      it "returns User even when azp is also present" do
        expect(validator.call(token: sign_jwt(valid_claims(azp: "some-client")))).to eq(user)
      end
    end

    context "when JWT has no email (ApiClient token)" do
      let_it_be(:api_client) { create(:api_client, oidc_client_id: "starmap-ci-agent", team_list: [create(:team)]) }

      def api_client_claims(overrides = {})
        {iss: issuer, aud: client_id, exp: 1.hour.from_now.to_i, azp: "starmap-ci-agent"}.merge(overrides)
      end

      it "returns ApiClient when azp matches oidc_client_id" do
        expect(validator.call(token: sign_jwt(api_client_claims))).to eq(api_client)
      end

      it "raises InvalidToken when azp does not match any ApiClient" do
        expect { validator.call(token: sign_jwt(api_client_claims(azp: "unknown-client"))) }.to raise_error(OidcTokenValidator::InvalidToken, /No API client found/)
      end

      it "raises InvalidToken when ApiClient is disabled" do
        api_client.update!(enabled: false)

        expect { validator.call(token: sign_jwt(api_client_claims)) }.to raise_error(OidcTokenValidator::InvalidToken, /No API client found/)
      end

      it "accepts aud=account from Keycloak service accounts" do
        expect(validator.call(token: sign_jwt(api_client_claims(aud: "account")))).to eq(api_client)
      end
    end

    it "raises TokenExpired when token is expired" do
      expect { validator.call(token: sign_jwt(valid_claims(exp: 1.hour.ago.to_i))) }.to raise_error(OidcTokenValidator::TokenExpired)
    end

    it "raises InvalidIssuer when issuer mismatches" do
      expect { validator.call(token: sign_jwt(valid_claims(iss: "http://evil.local"))) }.to raise_error(OidcTokenValidator::InvalidIssuer)
    end

    it "raises InvalidToken when audience mismatches" do
      expect { validator.call(token: sign_jwt(valid_claims(aud: "wrong-client"))) }.to raise_error(OidcTokenValidator::InvalidToken, /audience/)
    end

    it "accepts audience as array" do
      expect(validator.call(token: sign_jwt(valid_claims(aud: [client_id, "other"])))).to eq(user)
    end

    context "when signing key is wrong" do
      let(:other_key) { OpenSSL::PKey::RSA.new(2048) }
      let(:other_jwk) { JSON::JWK.new(other_key).tap { |j| j[:kid] = "other-kid" } }

      before do
        allow(Rails.cache).to receive(:fetch).with("oidc_jwks", expires_in: described_class::JWKS_TTL).and_return(JSON::JWK::Set.new("keys" => [other_jwk]))
      end

      it "raises InvalidToken" do
        expect { validator.call(token: sign_jwt(valid_claims)) }.to raise_error(OidcTokenValidator::InvalidToken)
      end
    end

    context "when OIDC provider is unreachable" do
      before do
        allow(Rails.cache).to receive(:fetch).with("oidc_jwks", expires_in: anything).and_yield
        allow(Rails.cache).to receive(:fetch).with("oidc_jwks_uri", expires_in: anything).and_yield
        allow(Faraday).to receive(:get).and_raise(Faraday::ConnectionFailed.new("refused"))
      end

      it "raises InvalidToken with provider error" do
        expect { validator.call(token: sign_jwt(valid_claims)) }.to raise_error(OidcTokenValidator::InvalidToken, /unavailable/)
      end
    end
  end
end
