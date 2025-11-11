require 'rails_helper'

# RSpec tests for ActionPlanPolicy
# Tests all role-based access control scenarios for action plans
RSpec.describe ActionPlanPolicy, type: :policy do
  subject { described_class }

  # Create test users for all roles
  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }

  # Create test data
  let_it_be(:technology) { create(:technology) }
  let_it_be(:quarter) { create(:quarter) }
  let_it_be(:other_team) { create(:team) }

  let_it_be(:own_team) { team_lead.team }

  # Create action plans for different scenarios
  let_it_be(:own_action_plan) { create(:action_plan, user: engineer, technology: technology, quarter: quarter, created_by: engineer) }
  let_it_be(:team_lead_action_plan) { create(:action_plan, user: team_lead, technology: technology, quarter: quarter, created_by: team_lead) }
  let_it_be(:other_team_user) { create(:engineer, team: other_team) }
  let_it_be(:other_team_action_plan) { create(:action_plan, user: other_team_user, technology: technology, quarter: quarter, created_by: other_team_user) }
  let_it_be(:assigned_user) { create(:engineer, team: own_team) }
  let_it_be(:assigned_action_plan) { create(:action_plan, :assigned, user: assigned_user, technology: technology, quarter: quarter, created_by: team_lead, assigned_to: engineer) }
  let_it_be(:unassigned_action_plan) { create(:action_plan, user: other_team_user, technology: technology, quarter: quarter, created_by: admin) }

  # Context: User is nil (unauthenticated)
  describe 'when user is nil' do
    let(:user) { nil }
    let(:record) { build(:action_plan) }

    permissions :index?, :create?, :update?, :destroy?, :approve?, :complete?, :pause?, :resume?, :assign_to?, :view_progress?, :edit?, :new? do
      it 'denies access' do
        expect(subject).not_to permit(user, record)
      end
    end

    permissions :show? do
      it 'denies access' do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: User is inactive
  describe 'when user is inactive' do
    let(:user) { inactive_user }
    let(:record) { build(:action_plan) }

    permissions :index?, :create?, :update?, :destroy?, :approve?, :complete?, :pause?, :resume?, :assign_to?, :view_progress?, :edit?, :new? do
      it 'denies access' do
        expect(subject).not_to permit(user, record)
      end
    end

    permissions :show? do
      it 'denies access' do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Index permission tests
  describe 'index? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { build(:action_plan) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { build(:action_plan) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }
      let(:record) { build(:action_plan) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { build(:action_plan) }

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
        context 'when viewing any action plan' do
          let(:record) { own_action_plan }

          it 'grants access to own action plan' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other action plan' do
            expect(subject).to permit(user, other_team_action_plan)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :show? do
        context 'when viewing any action plan' do
          let(:record) { own_action_plan }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other action plan' do
            expect(subject).to permit(user, other_team_action_plan)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :show? do
        context 'when viewing own team action plan' do
          let(:record) { team_lead_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing other team action plan' do
          let(:record) { other_team_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when viewing assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      permissions :show? do
        context 'when viewing own action plan' do
          let(:user) { engineer }
          let(:record) { own_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing assigned action plan' do
          let(:user) { engineer }
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing other user action plan' do
          let(:user) { engineer }
          let(:record) { team_lead_action_plan }
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
      let(:user) { admin }
      let(:record) { build(:action_plan, user: admin, created_by: admin) }

      permissions :create? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { build(:action_plan, user: unit_lead, created_by: unit_lead) }

      permissions :create? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :create? do
        context 'when creating action plan for own team member' do
          let(:record) { build(:action_plan, user: create(:engineer, team: own_team), created_by: team_lead) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when creating action plan for other team member' do
          let(:record) { build(:action_plan, user: build(:engineer, team: other_team), created_by: team_lead) }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when creating action plan for self' do
          let(:record) { build(:action_plan, user: team_lead, created_by: team_lead) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :create? do
        context 'when creating own action plan' do
          let(:record) { build(:action_plan, user: engineer, created_by: engineer) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when creating action plan for other user' do
          let(:record) { build(:action_plan, user: team_lead, created_by: engineer) }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # Update permission tests
  describe 'update? permission' do
    context 'for admin' do
      let(:user) { admin }

      permissions :update? do
        context 'when updating any action plan' do
          let(:record) { own_action_plan }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other action plan' do
            expect(subject).to permit(user, other_team_action_plan)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :update? do
        context 'when updating any action plan' do
          let(:record) { own_action_plan }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other action plan' do
            expect(subject).to permit(user, other_team_action_plan)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :update? do
        context 'when updating own team action plan' do
          let(:record) { team_lead_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when updating other team action plan' do
          let(:record) { other_team_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when updating assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :update? do
        context 'when updating own action plan' do
          let(:record) { own_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when updating assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when updating other user action plan' do
          let(:record) { team_lead_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # Destroy permission tests
  describe 'destroy? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { own_action_plan }

      permissions :destroy? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { own_action_plan }

      permissions :destroy? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }
      let(:record) { own_action_plan }

      permissions :destroy? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { own_action_plan }

      permissions :destroy? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Approve permission tests
  describe 'approve? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { own_action_plan }

      permissions :approve? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :approve? do
        context 'when approving any action plan' do
          let(:record) { own_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :approve? do
        context 'when approving own team action plan' do
          let(:record) { build(:action_plan, user: create(:engineer, team: own_team), technology: technology, quarter: quarter, created_by: create(:engineer, team: own_team)) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when approving other team action plan' do
          let(:record) { other_team_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { own_action_plan }

      permissions :approve? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Complete permission tests
  describe 'complete? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { own_action_plan }

      permissions :complete? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { own_action_plan }

      permissions :complete? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :complete? do
        context 'when completing own team action plan' do
          let(:record) { team_lead_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when completing other team action plan' do
          let(:record) { other_team_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when completing assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :complete? do
        context 'when completing own action plan' do
          let(:record) { own_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when completing assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when completing other user action plan' do
          let(:record) { team_lead_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # Pause permission tests
  describe 'pause? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { own_action_plan }

      permissions :pause? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { own_action_plan }

      permissions :pause? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :pause? do
        context 'when pausing own team action plan' do
          let(:record) { team_lead_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when pausing other team action plan' do
          let(:record) { other_team_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when pausing assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :pause? do
        context 'when pausing own action plan' do
          let(:record) { own_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when pausing assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when pausing other user action plan' do
          let(:record) { team_lead_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # Resume permission tests
  describe 'resume? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { own_action_plan }

      permissions :resume? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { own_action_plan }

      permissions :resume? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :resume? do
        context 'when resuming own team action plan' do
          let(:record) { team_lead_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when resuming other team action plan' do
          let(:record) { other_team_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when resuming assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :resume? do
        context 'when resuming own action plan' do
          let(:record) { own_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when resuming assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when resuming other user action plan' do
          let(:record) { team_lead_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # Assign to permission tests
  describe 'assign_to? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { own_action_plan }

      permissions :assign_to? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { own_action_plan }

      permissions :assign_to? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :assign_to? do
        context 'when assigning own team action plan' do
          let(:record) { team_lead_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when assigning other team action plan' do
          let(:record) { other_team_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { own_action_plan }

      permissions :assign_to? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # View progress permission tests
  describe 'view_progress? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { own_action_plan }

      permissions :view_progress? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { own_action_plan }

      permissions :view_progress? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :view_progress? do
        context 'when viewing progress of own team action plan' do
          let(:record) { team_lead_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing progress of other team action plan' do
          let(:record) { other_team_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when viewing progress of assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :view_progress? do
        context 'when viewing progress of own action plan' do
          let(:record) { own_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing progress of assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing progress of other user action plan' do
          let(:record) { team_lead_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # Edit permission tests (should mirror update?)
  describe 'edit? permission' do
    context 'for admin' do
      let(:user) { admin }

      permissions :edit? do
        context 'when editing any action plan' do
          let(:record) { own_action_plan }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other action plan' do
            expect(subject).to permit(user, other_team_action_plan)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :update? do
        context 'when editing any action plan' do
          let(:record) { own_action_plan }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other action plan' do
            expect(subject).to permit(user, other_team_action_plan)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :edit? do
        context 'when editing own team action plan' do
          let(:record) { team_lead_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when editing other team action plan' do
          let(:record) { other_team_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when editing assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :edit? do
        context 'when editing own action plan' do
          let(:record) { own_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when editing assigned action plan' do
          let(:record) { assigned_action_plan }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when editing other user action plan' do
          let(:record) { team_lead_action_plan }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # New permission tests (should mirror create?)
  describe 'new? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { build(:action_plan, user: admin, created_by: admin) }

      permissions :new? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { build(:action_plan, user: unit_lead, created_by: unit_lead) }

      permissions :new? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :new? do
        context 'when creating action plan for own team member' do
          let(:record) { build(:action_plan, user: create(:engineer, team: own_team), created_by: team_lead) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when creating action plan for other team member' do
          let(:record) { build(:action_plan, user: build(:engineer, team: other_team), created_by: team_lead) }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when creating action plan for self' do
          let(:record) { build(:action_plan, user: team_lead, created_by: team_lead) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :new? do
        context 'when creating own action plan' do
          let(:record) { build(:action_plan, user: engineer, created_by: engineer) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when creating action plan for other user' do
          let(:record) { build(:action_plan, user: team_lead, created_by: engineer) }
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

      it 'includes all action plans' do
        scope = ActionPlanPolicy::Scope.new(user, ActionPlan.all).resolve
        expect(scope.count).to be >= 0
        expect(scope).to include(own_action_plan, other_team_action_plan)
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      it 'includes all action plans' do
        scope = ActionPlanPolicy::Scope.new(user, ActionPlan.all).resolve
        expect(scope.count).to be >= 0
        expect(scope).to include(own_action_plan, other_team_action_plan)
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      it 'includes only own team and assigned action plans' do
        scope = ActionPlanPolicy::Scope.new(user, ActionPlan.all).resolve
        expect(scope).to include(team_lead_action_plan, assigned_action_plan)
        expect(scope).not_to include(other_team_action_plan)
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      it 'includes only own and assigned action plans' do
        scope = ActionPlanPolicy::Scope.new(user, ActionPlan.all).resolve
        expect(scope).to include(own_action_plan, assigned_action_plan)
        expect(scope).not_to include(team_lead_action_plan)
      end
    end

    context 'for nil user' do
      let(:user) { nil }

      it 'returns empty scope' do
        scope = ActionPlanPolicy::Scope.new(user, ActionPlan.all).resolve
        expect(scope).to be_empty
      end
    end
  end

  # Edge cases and special scenarios
  describe 'edge cases' do
    context 'when action_plan is nil' do
      let(:user) { admin }
      let(:record) { nil }

      permissions :index?, :new? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end

      permissions :show?, :update?, :destroy?, :approve?, :complete?, :pause?, :resume?, :assign_to?, :view_progress?, :edit? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'when user has no team assigned' do
      let(:user) { build(:engineer, team: nil) }
      let(:record) { build(:action_plan, user: user, technology: technology, quarter: quarter, created_by: user) }

      permissions :approve?, :assign_to? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end

      permissions :update?, :edit?, :complete?, :pause?, :resume? do
        it 'grants access for own action plan' do
          expect(subject).to permit(user, record)
        end
      end

      permissions :show?, :view_progress? do
        it 'grants access for own action plan' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'when team_lead is accessing team member action plan' do
      let(:user) { team_lead }
      let(:record) { build(:action_plan, user: create(:engineer, team: own_team), technology: technology, quarter: quarter, created_by: create(:engineer, team: own_team)) }

      permissions :show?, :update?, :edit?, :approve?, :complete?, :pause?, :resume?, :assign_to?, :view_progress? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'when engineer is accessing own action plan' do
      let(:user) { engineer }
      let(:record) { own_action_plan }

      permissions :show?, :update?, :edit?, :complete?, :pause?, :resume?, :view_progress? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end

      permissions :approve?, :assign_to? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end
end
