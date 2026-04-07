require "rails_helper"

RSpec.describe Admin::TeamTechnologyPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin, team: nil) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:unit_lead) { create(:unit_lead, team: nil) }
  let_it_be(:unit) { create(:unit, unit_lead: unit_lead) }
  let_it_be(:team_lead_user) { create(:team_lead) }
  let_it_be(:team) { create(:team, unit: unit) }
  let_it_be(:team_technology) { create(:team_technology, team: team) }

  permissions :update?, :destroy? do
    it "grants access to admin" do
      expect(subject).to permit(admin, [:admin, team_technology])
    end

    it "grants access to unit lead for team in their unit" do
      expect(subject).to permit(unit_lead, [:admin, team_technology])
    end

    it "denies access to unit lead for team in another unit" do
      other_unit = create(:unit)
      other_team = create(:team, unit: other_unit)
      other_tt = create(:team_technology, team: other_team)
      expect(subject).not_to permit(unit_lead, [:admin, other_tt])
    end

    it "denies access to team lead" do
      expect(subject).not_to permit(team_lead_user, [:admin, team_technology])
    end

    it "denies access to engineer" do
      expect(subject).not_to permit(engineer, [:admin, team_technology])
    end
  end

  describe "permitted_attributes" do
    it "includes technology_id, criticality, and target_experts" do
      policy = described_class.new(admin, [:admin, team_technology])
      expect(policy.permitted_attributes).to contain_exactly(:technology_id, :criticality, :target_experts)
    end
  end

  describe "Scope" do
    it "returns all for admin" do
      create_list(:team_technology, 3)
      scope = described_class::Scope.new(admin, TeamTechnology.all)
      expect(scope.resolve.count).to eq(TeamTechnology.count)
    end

    it "returns only unit's team technologies for unit lead" do
      unit_tts = create_list(:team_technology, 2, team: team)
      create_list(:team_technology, 3)
      scope = described_class::Scope.new(unit_lead, TeamTechnology.all)
      expect(scope.resolve).to match_array([team_technology] + unit_tts)
    end

    it "returns none for team lead" do
      create_list(:team_technology, 3)
      scope = described_class::Scope.new(team_lead_user, TeamTechnology.all)
      expect(scope.resolve.count).to eq(0)
    end

    it "returns none for engineer" do
      create_list(:team_technology, 3)
      scope = described_class::Scope.new(engineer, TeamTechnology.all)
      expect(scope.resolve.count).to eq(0)
    end
  end
end
