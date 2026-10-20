require "rails_helper"

RSpec.describe "MCP team_metrics", type: :request do
  include McpHelpers

  let_it_be(:team) { create(:team, name: "Backend") }
  let_it_be(:user) { create(:engineer, team: team) }
  let_it_be(:assessment_period) { create(:assessment_period, :current) }
  let_it_be(:other_team) { create(:team, name: "Frontend") }
  let_it_be(:stranger) { create(:engineer, team: other_team) }

  let_it_be(:past_assessment_period) { create(:assessment_period, status: :closed, is_current: false) }
  let_it_be(:technology) { create(:technology) }
  let_it_be(:team_technology) { create(:team_technology, team: team, technology: technology) }
  let_it_be(:api_client) { create(:api_client, team_list: [team]) }

  before { sign_in user }

  %w[monthly quarterly semiannual annual custom].each_with_index do |kind, index|
    it "selects #{kind} by id with the same response contract" do
      year = 2100 + index
      start_date = Date.new(year, 1, 1)
      months = {"monthly" => 1, "quarterly" => 3, "semiannual" => 6, "annual" => 12, "custom" => 2}.fetch(kind)
      period = create(:assessment_period, period_kind: kind, start_date: start_date, end_date: start_date.advance(months: months) - 1.day)
      result = mcp_call("team_metrics", {team_name: "Backend", period_id: period.id})
      expect(result.fetch("isError")).to be false
      data = mcp_payload(result)
      expect(data).to include("period_id" => period.id, "period_name" => period.full_name)
      expect(data).not_to have_key("quarter")
      AssessmentPeriod.where(is_current: true).update_all(is_current: false)
      period.update!(is_current: true)
      default = mcp_call("team_metrics", {team_name: "Backend"})
      expect(mcp_payload(default)).to eq(data)
    end
  end

  it "exposes only the period selector in the input schema" do
    tools = mcp_request("tools/list").fetch("result").fetch("tools")
    properties = tools.find { |tool| tool["name"] == "team_metrics" }.fetch("inputSchema").fetch("properties")
    expect(properties).to have_key("period_id")
    expect(properties.fetch("period_id").fetch("description")).to include("assessment_periods")
    expect(properties).not_to have_key("quarter")
  end

  it "rejects invalid period ids without silently selecting current" do
    ["bad", "1", 0, -1, 1.5].each do |id|
      json = mcp_request("tools/call", {name: "team_metrics", arguments: {team_name: "Backend", period_id: id}})
      expect(response).to have_http_status(:ok)
      expect(json["error"] || json.dig("result", "isError")).to be_present
    end
  end

  describe "tools/call" do
    context "when team exists and user has access" do
      it "returns metrics for current assessment_period" do
        result = mcp_call("team_metrics", {team_name: "Backend"})

        expect(result.fetch("isError")).to be false
        data = mcp_payload(result)
        expect(data["team"]).to eq("Backend")
        expect(data["period_name"]).to eq(assessment_period.full_name)
        expect(data).to have_key("coverage_index")
        expect(data).to have_key("maturity_index")
        expect(data).to have_key("red_zones_count")
        expect(data).to have_key("key_person_risks_count")
      end
    end

    context "when team not found" do
      it "returns error" do
        result = mcp_call("team_metrics", {team_name: "Unknown"})

        expect(result.fetch("isError")).to be true
        expect(result.fetch("content").first.fetch("text")).to include("not found")
      end
    end

    context "when user has no access to team" do
      before { sign_in stranger }

      it "returns error" do
        result = mcp_call("team_metrics", {team_name: "Backend"})

        expect(result.fetch("isError")).to be true
        expect(result.fetch("content").first.fetch("text")).to include("permission")
      end
    end

    context "when specific assessment_period provided" do
      it "returns error for unknown assessment_period" do
        result = mcp_call("team_metrics", {team_name: "Backend", period_id: 99999999})

        expect(result.fetch("isError")).to be true
        expect(result.fetch("content").first.fetch("text")).to include("not found")
      end
    end

    context "with team data" do
      before do
        create(:skill_rating, user: user, team: team, technology: technology, assessment_period: assessment_period, rating: 3, status: :approved, approved_by: user, approved_at: Time.current)
      end

      it "returns computed metrics" do
        result = mcp_call("team_metrics", {team_name: "Backend"})
        data = mcp_payload(result)

        expect(data["coverage_index"]).to be_a(Integer)
        expect(data["maturity_index"].to_f).to be_a(Float)
        expect(data["red_zones_count"]).to be_a(Integer)
        expect(data["key_person_risks_count"]).to be_a(Integer)
      end
    end

    context "when ApiClient is the identity" do
      before do
        sign_out user
        allow(OidcTokenValidator).to receive(:call).and_return(api_client)
      end

      it "returns metrics for team in team_ids" do
        result = mcp_call("team_metrics", {team_name: "Backend"}, token: "client-token")

        expect(result.fetch("isError")).to be false
        data = mcp_payload(result)
        expect(data["team"]).to eq("Backend")
      end

      it "returns forbidden error for team not in team_ids" do
        result = mcp_call("team_metrics", {team_name: "Frontend"}, token: "client-token")

        expect(result.fetch("isError")).to be true
        expect(result.fetch("content").first.fetch("text")).to eq("You do not have permission to view team 'Frontend'")
      end
    end
  end
end
