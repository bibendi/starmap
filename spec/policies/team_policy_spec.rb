require 'rails_helper'

# RSpec tests for TeamPolicy
# Tests all role-based access control scenarios
RSpec.describe TeamPolicy, type: :policy do
  subject { described_class }

  # Create test users for all roles
  let(:admin) { create(:admin) }
  let(:unit_lead) { create(:unit_lead) }
  let(:team_lead) { create(:team_lead) }
  let(:engineer) { create(:engineer) }
  let(:inactive_user) { create(:inactive_user) }

  # Create teams for testing
  let(:own_team) { team_lead.team }
  let(:other_team) { create(:team) }
  let(:other_team_lead) { create(:team_lead) }
  let(:other_team_engineer) { create(:engineer, team: other_team_lead.team) }

  # Context: User is nil (unauthenticated)
  describe 'when user is nil' do
    let(:user) { nil }
    let(:record) { build(:team) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit?, :manage_members?, :assign_team_lead?, :view_team_metrics? do
      it 'denies access' do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: User is inactive
  describe 'when user is inactive' do
    let(:user) { inactive_user }
    let(:record) { build(:team) }

    permissions :index?, :show?, :update?, :new?, :edit?, :manage_members?, :assign_team_lead?, :view_team_metrics? do
      it 'denies access' do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Index permission tests
  describe 'index? permission' do
    context 'for admin' do
      let(:user) { create(:admin) }
      let(:record) { build(:team) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { create(:unit_lead) }
      let(:record) { build(:team) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { create(:team_lead) }
      let(:record) { build(:team) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for engineer' do
      let(:user) { create(:engineer) }
      let(:record) { build(:team) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end
  end

  # Show permission tests
  describe 'show? permission' do
    context 'for admin' do
      let(:user) { admin }

      permissions :show? do
        context 'when viewing any team' do
          let(:record) { own_team }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other team' do
            expect(subject).to permit(user, other_team)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :show? do
        context 'when viewing any team' do
          let(:record) { own_team }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other team' do
            expect(subject).to permit(user, other_team)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :show? do
        context 'when viewing own team' do
          let(:record) { own_team }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing other team' do
          let(:record) { other_team }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      permissions :show? do
        context 'when viewing own team' do
          let(:user) { create(:engineer, team: own_team) }
          let(:record) { own_team }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing other team' do
          let(:user) { create(:engineer, team: own_team) }
          let(:record) { other_team }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # Create permission tests
  describe 'create? permission' do
    context 'for admin' do
      let(:user) { create(:admin) }
      let(:record) { build(:team) }

      permissions :create? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { create(:unit_lead) }
      let(:record) { build(:team) }

      permissions :create? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { create(:team_lead) }
      let(:record) { build(:team) }

      permissions :create? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'for engineer' do
      let(:user) { create(:engineer) }
      let(:record) { build(:team) }

      permissions :create? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Update permission tests
  describe 'update? permission' do
    context 'for admin' do
      let(:user) { admin }

      permissions :update? do
        context 'when updating any team' do
          let(:record) { own_team }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other team' do
            expect(subject).to permit(user, other_team)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :update? do
        context 'when updating any team' do
          let(:record) { own_team }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other team' do
            expect(subject).to permit(user, other_team)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :update? do
        context 'when updating own team' do
          let(:record) { own_team }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when updating other team' do
          let(:record) { other_team }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { own_team }

      permissions :update? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Destroy permission tests
  describe 'destroy? permission' do
    context 'for admin' do
      let(:user) { create(:admin) }
      let(:record) { build(:team) }

      permissions :destroy? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { create(:unit_lead) }
      let(:record) { build(:team) }

      permissions :destroy? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { create(:team_lead) }
      let(:record) { build(:team) }

      permissions :destroy? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'for engineer' do
      let(:user) { create(:engineer) }
      let(:record) { build(:team) }

      permissions :destroy? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # New permission tests (should mirror create?)
  describe 'new? permission' do
    context 'for admin' do
      let(:user) { create(:admin) }

      permissions :new? do
        it 'grants access' do
          expect(subject).to permit(user, build(:team))
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { create(:unit_lead) }

      permissions :new? do
        it 'grants access' do
          expect(subject).to permit(user, build(:team))
        end
      end
    end

    context 'for team_lead' do
      let(:user) { create(:team_lead) }

      permissions :new? do
        it 'denies access' do
          expect(subject).not_to permit(user, build(:team))
        end
      end
    end

    context 'for engineer' do
      let(:user) { create(:engineer) }

      permissions :new? do
        it 'denies access' do
          expect(subject).not_to permit(user, build(:team))
        end
      end
    end
  end

  # Edit permission tests (should mirror update?)
  describe 'edit? permission' do
    context 'for admin' do
      let(:user) { admin }

      permissions :edit? do
        context 'when editing any team' do
          let(:record) { own_team }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other team' do
            expect(subject).to permit(user, other_team)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :edit? do
        context 'when editing any team' do
          let(:record) { own_team }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other team' do
            expect(subject).to permit(user, other_team)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :edit? do
        context 'when editing own team' do
          let(:record) { own_team }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when editing other team' do
          let(:record) { other_team }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { own_team }

      permissions :edit? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Manage members permission tests
  describe 'manage_members? permission' do
    context 'for admin' do
      let(:user) { admin }

      permissions :manage_members? do
        context 'when managing any team' do
          let(:record) { own_team }

          it 'grants access to own team' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other team' do
            expect(subject).to permit(user, other_team)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :manage_members? do
        context 'when managing own team (as team lead)' do
          let(:team_as_lead) { create(:team_lead).team }
          let(:user_as_lead) { create(:team_lead, team: team_as_lead) }
          let(:record) { team_as_lead }
          let(:user) { user_as_lead }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when managing other team' do
          let(:record) { other_team }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when managing team where not team lead' do
          let(:record) { own_team }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :manage_members? do
        context 'when managing own team' do
          let(:record) { own_team }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when managing other team' do
          let(:record) { other_team }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { own_team }

      permissions :manage_members? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Assign team lead permission tests
  describe 'assign_team_lead? permission' do
    context 'for admin' do
      let(:user) { create(:admin) }
      let(:record) { build(:team) }

      permissions :assign_team_lead? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { create(:unit_lead) }
      let(:record) { build(:team) }

      permissions :assign_team_lead? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { create(:team_lead) }
      let(:record) { build(:team) }

      permissions :assign_team_lead? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'for engineer' do
      let(:user) { create(:engineer) }
      let(:record) { build(:team) }

      permissions :assign_team_lead? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # View team metrics permission tests
  describe 'view_team_metrics? permission' do
    context 'for admin' do
      let(:user) { admin }

      permissions :view_team_metrics? do
        context 'when viewing metrics for any team' do
          let(:record) { own_team }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other team' do
            expect(subject).to permit(user, other_team)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :view_team_metrics? do
        context 'when viewing metrics for any team' do
          let(:record) { own_team }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other team' do
            expect(subject).to permit(user, other_team)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :view_team_metrics? do
        context 'when viewing metrics for own team' do
          let(:record) { own_team }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing metrics for other team' do
          let(:record) { other_team }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      permissions :view_team_metrics? do
        context 'when viewing metrics for own team' do
          let(:user) { create(:engineer, team: own_team) }
          let(:record) { own_team }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing metrics for other team' do
          let(:user) { create(:engineer, team: own_team) }
          let(:record) { other_team }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # Scope tests
  describe 'Scope' do
    context 'for admin' do
      let(:user) { admin }

      it 'includes all teams' do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(own_team, other_team)
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      it 'includes all teams' do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(own_team, other_team)
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      it 'includes only own team' do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope).to include(own_team)
        expect(scope).not_to include(other_team)
      end
    end

    context 'for engineer' do
      let(:user) { create(:engineer, team: own_team) }

      it 'includes only own team' do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope).to include(own_team)
        expect(scope).not_to include(other_team)
      end
    end

    context 'for nil user' do
      let(:user) { nil }

      it 'returns empty scope' do
        scope = TeamPolicy::Scope.new(user, Team.all).resolve
        expect(scope).to be_empty
      end
    end
  end

  # Edge cases and special scenarios
  describe 'edge cases' do
    context 'when team is nil' do
      let(:user) { admin }
      let(:record) { nil }

      permissions :show?, :update?, :destroy?, :edit?, :manage_members?, :assign_team_lead?, :view_team_metrics? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'when user has no team assigned' do
      let(:user) { create(:engineer, team: nil) }
      let(:record) { own_team }

      permissions :show?, :update?, :edit?, :view_team_metrics? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'when team_lead is viewing team they lead' do
      let(:user) { team_lead }
      let(:record) { own_team }

      permissions :show?, :update?, :edit?, :manage_members?, :view_team_metrics? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'when engineer is from same team as team_lead' do
      permissions :show?, :view_team_metrics? do
        let(:user) { create(:engineer, team: own_team) }
        let(:record) { own_team }

        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end

      permissions :update?, :edit?, :manage_members?, :assign_team_lead? do
        let(:user) { create(:engineer, team: own_team) }
        let(:record) { own_team }

        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end
end
