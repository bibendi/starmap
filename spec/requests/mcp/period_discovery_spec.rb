require "rails_helper"

RSpec.describe "MCP period discovery workflow", type: :request do
  include McpHelpers

  let_it_be(:team) { create(:team, name: "Backend") }
  let_it_be(:other_team) { create(:team, name: "Frontend") }
  let_it_be(:user) { create(:engineer, team: team) }
  let_it_be(:api_client) { create(:api_client, team_list: [team]) }
  let_it_be(:historical_period) { create(:assessment_period, year: 2100, quarter_number: 1, status: :archived) }
  let_it_be(:current_period) { create(:assessment_period, :current, year: 2101, quarter_number: 1) }

  context "with a User session" do
    before { sign_in user }

    it "discovers and selects a historical period" do
      catalogue = mcp_payload(mcp_call("assessment_periods")).fetch("periods")
      selected = catalogue.find { |entry| entry["id"] == historical_period.id }
      metrics = mcp_payload(mcp_call("team_metrics", {team_name: team.name, period_id: selected.fetch("id")}))
      expect(metrics).to include("period_id" => selected["id"], "period_name" => selected["name"])
    end

    it "recovers from missing current using the catalogue" do
      AssessmentPeriod.update_all(is_current: false)
      error = mcp_call("team_metrics", {team_name: team.name})
      expect(error.fetch("isError")).to be true
      expect(error.fetch("content").first.fetch("text")).to include("No current assessment period", "assessment_periods", "period_id")
      selected = mcp_payload(mcp_call("assessment_periods")).fetch("periods").first
      metrics = mcp_payload(mcp_call("team_metrics", {team_name: team.name, period_id: selected.fetch("id")}))
      expect(metrics).to include("period_id" => selected["id"], "period_name" => selected["name"])
    end
  end

  context "with an ApiClient Bearer token" do
    before { allow(OidcTokenValidator).to receive(:call).and_return(api_client) }

    it "discovers periods but still enforces team scope" do
      selected = mcp_payload(mcp_call("assessment_periods", token: "client-token")).fetch("periods").first
      arguments = {team_name: team.name, period_id: selected.fetch("id")}
      expect(mcp_payload(mcp_call("team_metrics", arguments, token: "client-token")))
        .to include("period_id" => selected["id"], "period_name" => selected["name"])
      denied = mcp_call("team_metrics", arguments.merge(team_name: other_team.name), token: "client-token")
      expect(denied.fetch("isError")).to be true
      expect(denied.fetch("content").first.fetch("text")).to include("permission")
    end
  end
end
