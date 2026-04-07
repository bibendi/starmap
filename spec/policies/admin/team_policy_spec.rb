require "rails_helper"

RSpec.describe Admin::TeamPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:user, role: "admin", team: nil) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:unit_lead) { create(:unit_lead, team: nil) }
  let_it_be(:unit) { create(:unit, unit_lead: unit_lead) }
  let_it_be(:team_lead_user) { create(:team_lead) }
  let_it_be(:team) { create(:team, unit: unit) }

  permissions :index?, :create?, :new? do
    it "grants access to admin" do
      expect(subject).to permit(admin, [:admin, team])
    end

    it "grants access to unit lead" do
      expect(subject).to permit(unit_lead, [:admin, team])
    end

    it "denies access to team lead" do
      expect(subject).not_to permit(team_lead_user, [:admin, team])
    end

    it "denies access to engineer" do
      expect(subject).not_to permit(engineer, [:admin, team])
    end
  end

  permissions :show?, :edit?, :update?, :destroy? do
    it "grants access to admin" do
      expect(subject).to permit(admin, [:admin, team])
    end

    it "grants access to unit lead for team in their unit" do
      expect(subject).to permit(unit_lead, [:admin, team])
    end

    it "denies access to unit lead for team in another unit" do
      other_unit = create(:unit)
      other_team = create(:team, unit: other_unit)
      expect(subject).not_to permit(unit_lead, [:admin, other_team])
    end

    it "denies access to team lead" do
      expect(subject).not_to permit(team_lead_user, [:admin, team])
    end

    it "denies access to engineer" do
      expect(subject).not_to permit(engineer, [:admin, team])
    end
  end

  describe "Scope" do
    it "returns all teams for admin" do
      create_list(:team, 3)
      scope = described_class::Scope.new(admin, Team.all)
      total = Team.count
      expect(scope.resolve.count).to eq(total)
    end

    it "returns only unit's teams for unit lead" do
      unit_teams = create_list(:team, 2, unit: unit)
      create_list(:team, 3)

      scope = described_class::Scope.new(unit_lead, Team.all)
      expect(scope.resolve).to match_array([team] + unit_teams)
    end

    it "returns none for team lead" do
      create_list(:team, 3)
      scope = described_class::Scope.new(team_lead_user, Team.all)
      expect(scope.resolve.count).to eq(0)
    end

    it "returns none for engineer" do
      create_list(:team, 3)
      scope = described_class::Scope.new(engineer, Team.all)
      expect(scope.resolve.count).to eq(0)
    end
  end
end
