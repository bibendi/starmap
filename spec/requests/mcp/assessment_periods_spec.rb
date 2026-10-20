require "rails_helper"

RSpec.describe "MCP assessment_periods", type: :request do
  include McpHelpers

  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:engineer, team: team) }
  let_it_be(:api_client) { create(:api_client, team_list: [team]) }
  let_it_be(:periods) do
    %w[custom annual semiannual quarterly monthly].each_with_index.map do |kind, index|
      start_date = Date.new(2100 - index, 1, 1)
      months = {"monthly" => 1, "quarterly" => 3, "semiannual" => 6, "annual" => 12, "custom" => 2}.fetch(kind)
      create(:assessment_period, period_kind: kind, start_date: start_date,
        end_date: start_date.advance(months: months) - 1.day,
        status: %w[closed archived active draft closed][index])
    end
  end

  before { sign_in user }

  let(:result) { mcp_call("assessment_periods") }
  let(:catalogue) { mcp_payload(result).fetch("periods") }

  it "publishes an empty input schema and read-only annotations" do
    tools = mcp_request("tools/list").fetch("result").fetch("tools")
    tool = tools.find { |entry| entry["name"] == "assessment_periods" }
    expect(tool.fetch("inputSchema")).to include("type" => "object", "properties" => {})
    expect(tool.fetch("inputSchema").fetch("required", [])).to eq([])
    expect(tool.fetch("annotations")).to include(
      "readOnlyHint" => true, "destructiveHint" => false,
      "idempotentHint" => true, "openWorldHint" => false
    )
  end

  it "returns every kind and status in chronological order without requiring ratings" do
    expect(catalogue.pluck("id")).to eq(periods.reverse.map(&:id))
    expect(catalogue.pluck("period_kind")).to match_array(AssessmentPeriod.period_kinds.keys)
    expect(catalogue.pluck("status").uniq).to match_array(AssessmentPeriod.statuses.keys)
    expect(SkillRating.count).to eq(0)
  end

  it "returns only the documented metadata with ISO dates" do
    periods.reverse.zip(catalogue).each do |period, entry|
      expect(entry).to eq(
        "id" => period.id, "name" => period.full_name,
        "period_kind" => period.period_kind, "status" => period.status,
        "start_date" => period.start_date.iso8601, "end_date" => period.end_date.iso8601,
        "evaluation_start_date" => period.evaluation_start_date.iso8601,
        "evaluation_end_date" => period.evaluation_end_date.iso8601,
        "is_current" => period.is_current?
      )
    end
  end

  it "preserves the stored current flag for a closed period" do
    expect(catalogue.find { |entry| entry["id"] == periods.first.id }).to include(
      "status" => "closed", "is_current" => true
    )
  end

  it "works without a current period" do
    AssessmentPeriod.update_all(is_current: false)
    expect(catalogue.pluck("is_current")).to all(be false)
    expect(catalogue.size).to eq(periods.size)
  end

  it "returns an empty catalogue successfully" do
    AssessmentPeriod.includes(:skill_ratings).destroy_all
    expect(catalogue).to eq([])
  end

  it "does not mutate periods or ratings" do
    before_periods = AssessmentPeriod.order(:id).map(&:attributes)
    before_ratings = SkillRating.order(:id).map(&:attributes)
    result
    expect(AssessmentPeriod.order(:id).map(&:attributes)).to eq(before_periods)
    expect(SkillRating.order(:id).map(&:attributes)).to eq(before_ratings)
  end

  context "with an ApiClient Bearer token" do
    before do
      sign_out user
      allow(OidcTokenValidator).to receive(:call).and_return(api_client)
    end

    let(:result) { mcp_call("assessment_periods", token: "client-token") }

    it "returns the complete catalogue regardless of team scope" do
      expect(catalogue.pluck("id")).to eq(periods.reverse.map(&:id))
    end

    it "returns a class-level policy denial without catalogue data" do
      api_client.update!(permissions: ["units:read"])
      expect(result.fetch("isError")).to be true
      expect(response).to have_http_status(:ok)
      expect(result.fetch("content").first.fetch("text"))
        .to eq("You do not have permission to view assessmentperiod 'AssessmentPeriod'")
    end
  end
end
