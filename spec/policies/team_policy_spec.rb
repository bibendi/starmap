require "rails_helper"

# RSpec tests for TeamPolicy
# Tests all role-based access control scenarios
RSpec.describe TeamPolicy, type: :policy do
  subject { described_class }

  # Create test users for all roles
  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }

  # Create teams for testing
  let_it_be(:other_team) { create(:team) }
  let_it_be(:other_team_lead) { create(:team_lead) }
  let_it_be(:other_team_engineer) { create(:engineer, team: other_team_lead.team) }

  # Context: User is nil (unauthenticated)
  describe "when user is nil" do
    let(:user) { nil }
    let(:record) { build(:team) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit?, :manage_members?, :assign_team_lead?, :view_team_metrics? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: User is inactive
  describe "when user is inactive" do
    let(:user) { inactive_user }
    let(:record) { build(:team) }

    permissions :index?, :show?, :update?, :new?, :edit?, :manage_members?, :assign_team_lead?, :view_team_metrics? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: Role-based access control
  context "for admin" do
    let(:user) { admin }
    let(:record) { build(:team) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit?, :manage_members?, :assign_team_lead?, :view_team_metrics? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end
  end

  context "for unit_lead" do
    let(:user) { unit_lead }
    let(:record) { build(:team) }

    permissions :index?, :show?, :create?, :update?, :new?, :edit?, :manage_members?, :assign_team_lead?, :view_team_metrics? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end

    permissions :destroy? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  context "for team_lead" do
    let(:user) { team_lead }

    permissions :index? do
      it "grants access" do
        expect(subject).to permit(user, build(:team))
      end
    end

    permissions :create?, :destroy?, :new?, :assign_team_lead? do
      it "denies access" do
        expect(subject).not_to permit(user, build(:team))
      end
    end

    permissions :show?, :update?, :edit?, :manage_members?, :view_team_metrics? do
      context "when accessing own team" do
        let(:record) { team_lead.team }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when accessing other team" do
        let(:record) { other_team }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  context "for engineer" do
    let(:user) { engineer }

    permissions :create?, :update?, :destroy?, :new?, :edit?, :manage_members?, :assign_team_lead? do
      it "denies access" do
        expect(subject).not_to permit(user, build(:team))
      end
    end

    permissions :index? do
      it "grants access" do
        expect(subject).to permit(user, build(:team))
      end
    end

    permissions :show?, :view_team_metrics? do
      context "when accessing own team" do
        let(:record) { engineer.team }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when accessing other team" do
        let(:record) { other_team }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Scope tests
  describe "Scope" do
    context "for admin" do
      let(:user) { admin }

      it "includes all teams" do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(team_lead.team, other_team)
      end
    end

    context "for unit_lead" do
      let(:user) { unit_lead }

      it "includes all teams" do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(team_lead.team, other_team)
      end
    end

    context "for team_lead" do
      let(:user) { team_lead }

      it "includes only own team" do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope).to include(team_lead.team)
        expect(scope).not_to include(other_team)
      end
    end

    context "for engineer" do
      let(:user) { build(:engineer, team: team_lead.team) }

      it "includes only own team" do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope).to include(team_lead.team)
        expect(scope).not_to include(other_team)
      end
    end

    context "for nil user" do
      let(:user) { nil }

      it "returns empty scope" do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope).to be_empty
      end
    end
  end

  # Edge cases and special scenarios
  describe "edge cases" do
    context "when team is nil" do
      let(:user) { admin }
      let(:record) { nil }

      permissions :show?, :update?, :destroy?, :edit?, :manage_members?, :assign_team_lead?, :view_team_metrics? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context "when user has no team assigned" do
      let(:user) { build(:engineer, team: nil) }
      let(:record) { team_lead.team }

      permissions :show?, :update?, :edit?, :view_team_metrics? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context "when team_lead is viewing team they lead" do
      let(:user) { team_lead }
      let(:record) { team_lead.team }

      permissions :show?, :update?, :edit?, :manage_members?, :view_team_metrics? do
        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end
    end

    context "when engineer is from same team as team_lead" do
      permissions :show?, :view_team_metrics? do
        let(:user) { build(:engineer, team: team_lead.team) }
        let(:record) { team_lead.team }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      permissions :update?, :edit?, :manage_members?, :assign_team_lead? do
        let(:user) { build(:engineer, team: team_lead.team) }
        let(:record) { team_lead.team }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end
end
