require "rails_helper"

RSpec.describe ApiClient::TeamPolicy, type: :policy do
  let_it_be(:team) { create(:team) }
  let_it_be(:other_team) { create(:team) }

  describe "#show?" do
    context "when ApiClient has teams:read and team is in team_ids" do
      let(:api_client) { build(:api_client, permissions: ["teams:read"], team_ids: [team.id]) }

      it "returns true" do
        expect(described_class.new(api_client, team).show?).to be true
      end
    end

    context "when team is not in team_ids" do
      let(:api_client) { build(:api_client, permissions: ["teams:read"], team_ids: [other_team.id]) }

      it "returns false" do
        expect(described_class.new(api_client, team).show?).to be false
      end
    end

    context "when ApiClient lacks teams:read permission" do
      let(:api_client) { build(:api_client, permissions: ["units:read"], team_ids: [team.id]) }

      it "returns false" do
        expect(described_class.new(api_client, team).show?).to be false
      end
    end

    context "when ApiClient is disabled" do
      let(:api_client) { build(:api_client, :disabled, permissions: ["teams:read"], team_ids: [team.id]) }

      it "returns false" do
        expect(described_class.new(api_client, team).show?).to be false
      end
    end
  end

  describe "#view_team_metrics?" do
    let(:api_client) { build(:api_client, permissions: ["teams:read"], team_ids: [team.id]) }

    it "delegates to show?" do
      policy = described_class.new(api_client, team)
      expect(policy.view_team_metrics?).to eq(policy.show?)
    end
  end
end
