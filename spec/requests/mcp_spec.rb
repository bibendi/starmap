require "rails_helper"

RSpec.describe "Mcp", type: :request do
  let_it_be(:team) { create(:team, name: "Backend") }
  let_it_be(:user) { create(:engineer, team: team) }

  def mcp_headers(token: nil)
    headers = {"CONTENT_TYPE" => "application/json"}
    headers["AUTHORIZATION"] = "Bearer #{token}" if token
    headers
  end

  def mcp_request(method:, id:, params: {})
    {jsonrpc: "2.0", id: id, method: method, params: params}.to_json
  end

  describe "POST /mcp" do
    context "without authorization header" do
      it "returns 401" do
        post "/mcp", params: mcp_request(method: "initialize", id: 1, params: {protocolVersion: "2025-03-26", capabilities: {}, clientInfo: {name: "test", version: "1.0.0"}}), headers: {"CONTENT_TYPE" => "application/json"}

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with invalid token" do
      before do
        allow(OidcTokenValidator).to receive(:call).and_raise(OidcTokenValidator::InvalidToken, "Invalid")
      end

      it "returns 401" do
        post "/mcp", params: mcp_request(method: "initialize", id: 1, params: {}), headers: mcp_headers(token: "bad-token")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when signed in via Devise" do
      before { sign_in user }

      it "handles initialize request" do
        post "/mcp", params: mcp_request(method: "initialize", id: 1, params: {protocolVersion: "2025-03-26", capabilities: {}, clientInfo: {name: "test", version: "1.0.0"}}), headers: mcp_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["result"]["serverInfo"]["name"]).to eq("starmap")
      end

      it "lists available tools" do
        post "/mcp", params: mcp_request(method: "tools/list", id: 2), headers: mcp_headers

        expect(response).to have_http_status(:ok)
        tool_names = response.parsed_body["result"]["tools"].pluck("name")
        expect(tool_names).to include("team_metrics")
      end

      it "calls team_metrics tool" do
        create(:quarter, :current)

        post "/mcp", params: mcp_request(method: "tools/call", id: 3, params: {name: "team_metrics", arguments: {team_name: team.name}}), headers: mcp_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["result"]["isError"]).to be false
        data = JSON.parse(json["result"]["content"].first["text"])
        expect(data["team"]).to eq("Backend")
      end

      it "returns error for unknown tool" do
        post "/mcp", params: mcp_request(method: "tools/call", id: 4, params: {name: "unknown_tool", arguments: {}}), headers: mcp_headers

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["error"]).to be_present
      end
    end

    context "when authenticated as ApiClient via Bearer token" do
      let_it_be(:api_client) { create(:api_client, oidc_client_id: "test-ci-agent", team_list: [team]) }

      before do
        allow(OidcTokenValidator).to receive(:call).and_return(api_client)
      end

      it "authenticates and calls team_metrics for authorized team" do
        create(:quarter, :current)

        post "/mcp", params: mcp_request(method: "tools/call", id: 5, params: {name: "team_metrics", arguments: {team_name: team.name}}), headers: mcp_headers(token: "api-client-token")

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["result"]["isError"]).to be false
      end

      it "returns authorization error for unauthorized team" do
        other_team = create(:team, name: "Unauthorized")

        post "/mcp", params: mcp_request(method: "tools/call", id: 6, params: {name: "team_metrics", arguments: {team_name: other_team.name}}), headers: mcp_headers(token: "api-client-token")

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["result"]["isError"]).to be true
        expect(json["result"]["content"].first["text"]).to include("permission")
      end

      it "returns 401 for disabled ApiClient" do
        api_client.update!(enabled: false)
        allow(OidcTokenValidator).to receive(:call).and_raise(OidcTokenValidator::InvalidToken, "No API client found")

        post "/mcp", params: mcp_request(method: "initialize", id: 7, params: {}), headers: mcp_headers(token: "disabled-token")

        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "when existing User Bearer token (regression)" do
      before do
        allow(OidcTokenValidator).to receive(:call).and_return(user)
      end

      it "still works" do
        create(:quarter, :current)

        post "/mcp", params: mcp_request(method: "tools/call", id: 8, params: {name: "team_metrics", arguments: {team_name: team.name}}), headers: mcp_headers(token: "user-token")

        expect(response).to have_http_status(:ok)
        json = response.parsed_body
        expect(json["result"]["isError"]).to be false
      end
    end
  end
end
