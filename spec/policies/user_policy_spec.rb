require "rails_helper"

RSpec.describe UserPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }
  let_it_be(:user_from_same_team) { create(:engineer, team: team_lead.team) }
  let_it_be(:user_from_different_team) { create(:engineer) }

  describe "when user is nil" do
    let(:user) { nil }
    let(:record) { build(:user) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit?, :view_sensitive_data? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  describe "when user is inactive" do
    let(:user) { inactive_user }
    let(:record) { build(:user) }

    permissions :index?, :show?, :update?, :new?, :edit?, :view_sensitive_data? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  context "for admin" do
    let(:user) { admin }
    let(:record) { build(:user) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit?, :view_sensitive_data? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end
  end

  context "for unit_lead" do
    let(:user) { unit_lead }
    let(:record) { build(:user) }

    permissions :index?, :show?, :create?, :update?, :new?, :edit?, :view_sensitive_data? do
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
        expect(subject).to permit(user, build(:user))
      end
    end

    permissions :create?, :destroy?, :new?, :view_sensitive_data? do
      it "denies access" do
        expect(subject).not_to permit(user, build(:user))
      end
    end

    permissions :show?, :update?, :edit? do
      context "when viewing/editing themselves" do
        let(:record) { team_lead }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when viewing/editing team member" do
        let(:record) { user_from_same_team }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when viewing/editing user from different team" do
        let(:record) { user_from_different_team }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  context "for engineer" do
    let(:user) { engineer }

    permissions :index?, :create?, :destroy?, :new?, :view_sensitive_data? do
      it "denies access" do
        expect(subject).not_to permit(user, build(:user))
      end
    end

    permissions :show?, :update?, :edit? do
      context "when viewing/editing themselves" do
        let(:record) { engineer }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when viewing/editing other user" do
        let(:record) { build(:user) }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  describe "Scope" do
    let(:other_team_lead) { create(:team_lead) }
    let(:other_team_engineer) { create(:engineer, team: other_team_lead.team) }

    context "for admin" do
      let(:user) { admin }

      it "includes all users" do
        scope = UserPolicy::Scope.new(user, User.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(admin, team_lead, unit_lead, engineer, user_from_same_team, user_from_different_team)
      end
    end

    context "for unit_lead" do
      let(:user) { unit_lead }

      it "includes all users" do
        scope = UserPolicy::Scope.new(user, User.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(admin, team_lead, unit_lead, engineer, user_from_same_team, user_from_different_team)
      end
    end

    context "for team_lead" do
      let(:user) { team_lead }

      it "includes only team members and themselves" do
        scope = UserPolicy::Scope.new(user, User.all).resolve
        expect(scope).to include(team_lead, user_from_same_team)
        expect(scope).not_to include(user_from_different_team, other_team_lead, other_team_engineer)
      end
    end

    context "for engineer" do
      let(:user) { engineer }

      it "includes only themselves" do
        scope = UserPolicy::Scope.new(user, User.all).resolve
        expect(scope).to include(engineer)
        expect(scope).not_to include(admin, team_lead, unit_lead, user_from_same_team, user_from_different_team)
      end
    end

    context "for nil user" do
      let(:user) { nil }

      it "returns empty scope" do
        scope = UserPolicy::Scope.new(user, User.all).resolve
        expect(scope).to be_empty
      end
    end
  end

  describe "edge cases" do
    context "when user is team lead but viewing a user without team" do
      let(:user) { team_lead }
      let(:record) { build(:user, team: nil) }

      permissions :show?, :update?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context "when user is viewing another team lead from their team" do
      let(:user) { team_lead }
      let(:other_team_lead_in_team) { build(:team_lead, team: team_lead.team) }
      let(:record) { other_team_lead_in_team }

      permissions :show?, :update? do
        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end
    end

    context "when record is nil" do
      let(:user) { admin }
      let(:record) { nil }

      permissions :show?, :update?, :destroy?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end
end
