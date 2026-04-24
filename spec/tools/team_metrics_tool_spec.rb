require "rails_helper"

RSpec.describe TeamMetricsTool, type: :service do
  let_it_be(:team) { create(:team, name: "Backend") }
  let_it_be(:user) { create(:engineer, team: team) }
  let_it_be(:quarter) { create(:quarter, :current) }
  let_it_be(:other_team) { create(:team, name: "Frontend") }
  let_it_be(:stranger) { create(:engineer, team: other_team) }

  let(:server_context) { {current_user: user} }

  describe ".call" do
    context "when team exists and user has access" do
      it "returns metrics for current quarter" do
        result = described_class.call(team_name: "Backend", server_context: server_context)

        expect(result.error?).to be false
        data = JSON.parse(result.content.first[:text])
        expect(data["team"]).to eq("Backend")
        expect(data["quarter"]).to eq(quarter.full_name)
        expect(data).to have_key("coverage_index")
        expect(data).to have_key("maturity_index")
        expect(data).to have_key("red_zones_count")
        expect(data).to have_key("key_person_risks_count")
      end
    end

    context "when team not found" do
      it "returns error" do
        result = described_class.call(team_name: "Unknown", server_context: server_context)

        expect(result.error?).to be true
        expect(result.content.first[:text]).to include("not found")
      end
    end

    context "when user has no access to team" do
      it "returns error" do
        result = described_class.call(team_name: "Backend", server_context: {current_user: stranger})

        expect(result.error?).to be true
        expect(result.content.first[:text]).to include("permission")
      end
    end

    context "when no active quarter" do
      before { quarter.update!(is_current: false) }

      it "returns error" do
        result = described_class.call(team_name: "Backend", server_context: server_context)

        expect(result.error?).to be true
        expect(result.content.first[:text]).to include("No active quarter")
      end
    end

    context "when specific quarter provided" do
      let_it_be(:past_quarter) { create(:quarter, status: :closed, is_current: false) }

      it "returns metrics for specified quarter" do
        result = described_class.call(team_name: "Backend", quarter: past_quarter.full_name, server_context: server_context)

        expect(result.error?).to be false
        data = JSON.parse(result.content.first[:text])
        expect(data["quarter"]).to eq(past_quarter.full_name)
      end

      it "returns error for unknown quarter" do
        result = described_class.call(team_name: "Backend", quarter: "2020 Q1", server_context: server_context)

        expect(result.error?).to be true
        expect(result.content.first[:text]).to include("not found")
      end
    end

    context "with team data" do
      let_it_be(:technology) { create(:technology) }
      let_it_be(:team_technology) { create(:team_technology, team: team, technology: technology) }

      before do
        create(:skill_rating, user: user, team: team, technology: technology, quarter: quarter, rating: 3, status: :approved, approved_by: user, approved_at: Time.current)
      end

      it "returns computed metrics" do
        result = described_class.call(team_name: "Backend", server_context: server_context)
        data = JSON.parse(result.content.first[:text])

        expect(data["coverage_index"]).to be_a(Integer)
        expect(data["maturity_index"].to_f).to be_a(Float)
        expect(data["red_zones_count"]).to be_a(Integer)
        expect(data["key_person_risks_count"]).to be_a(Integer)
      end
    end
  end
end
