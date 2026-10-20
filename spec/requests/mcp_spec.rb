require "rails_helper"

RSpec.describe "MCP endpoint", type: :request do
  include McpHelpers

  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:engineer, team: team) }
  let_it_be(:api_client) { create(:api_client, team_list: [team]) }

  it "returns HTTP 401 without authentication" do
    mcp_request("initialize")
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns HTTP 401 for an invalid token" do
    allow(OidcTokenValidator).to receive(:call).and_raise(OidcTokenValidator::InvalidToken, "Invalid")
    mcp_request("initialize", token: "invalid-token")
    expect(response).to have_http_status(:unauthorized)
  end

  it "returns HTTP 401 when a disabled machine client cannot authenticate" do
    api_client.update!(enabled: false)
    allow(OidcTokenValidator).to receive(:call).and_raise(OidcTokenValidator::InvalidToken, "No API client found")
    mcp_request("initialize", token: "disabled-token")
    expect(response).to have_http_status(:unauthorized)
  end

  context "with a User session" do
    before { sign_in user }

    it "initializes the server" do
      json = mcp_request("initialize", {
        protocolVersion: "2025-03-26", capabilities: {},
        clientInfo: {name: "test", version: "1.0.0"}
      })
      expect(response).to have_http_status(:ok)
      expect(json.fetch("result").fetch("serverInfo").fetch("name")).to eq("starmap")
    end

    it "lists registered tools" do
      tools = mcp_request("tools/list").fetch("result").fetch("tools")
      expect(response).to have_http_status(:ok)
      expect(tools.pluck("name")).to include("team_metrics", "assessment_periods")
    end

    it "returns a JSON-RPC error for an unknown tool" do
      json = mcp_request("tools/call", {name: "unknown_tool", arguments: {}})
      expect(response).to have_http_status(:ok)
      expect(json["error"]).to be_present
    end
  end

  context "with a User Bearer token" do
    before { allow(OidcTokenValidator).to receive(:call).and_return(user) }

    it "authenticates and dispatches a tool call" do
      expect(mcp_payload(mcp_call("assessment_periods", token: "user-token"))).to eq("periods" => [])
    end
  end

  context "with an ApiClient Bearer token" do
    before { allow(OidcTokenValidator).to receive(:call).and_return(api_client) }

    it "authenticates and dispatches a tool call" do
      expect(mcp_payload(mcp_call("assessment_periods", token: "client-token"))).to eq("periods" => [])
    end
  end
end
