require 'rails_helper'

# RSpec tests for DashboardPolicy
# Tests all role-based access control scenarios for dashboard permissions
RSpec.describe DashboardPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }

  # Context: User is nil (unauthenticated)
  describe 'when user is nil' do
    let(:user) { nil }

    permissions :overview?, :personal? do
      it 'denies access' do
        expect(subject).not_to permit(user, nil)
      end
    end
  end

  # Context: User is inactive
  describe 'when user is inactive' do
    let(:user) { inactive_user }

    permissions :overview?, :personal? do
      it 'denies access' do
        expect(subject).not_to permit(user, nil)
      end
    end
  end

  # Context: Role-based access control
  context 'for admin' do
    let(:user) { admin }

    permissions :overview?, :personal? do
      it 'grants access' do
        expect(subject).to permit(user, nil)
      end
    end
  end

  context 'for unit_lead' do
    let(:user) { unit_lead }

    permissions :overview?, :personal? do
      it 'grants access' do
        expect(subject).to permit(user, nil)
      end
    end
  end

  context 'for team_lead' do
    let(:user) { team_lead }

    permissions :personal? do
      context 'when viewing their own dashboard' do
        it 'grants access' do
          expect(subject).to permit(user, user)
        end
      end

      context 'when viewing team member dashboard' do
        let(:user_from_same_team) { create(:engineer, team: team_lead.team) }
        it 'grants access' do
          expect(subject).to permit(user, user_from_same_team)
        end
      end

      context 'when viewing user from different team' do
        let(:user_from_different_team) { create(:engineer) }
        it 'grants access' do
          expect(subject).to permit(user, user_from_different_team)
        end
      end
    end
  end

  context 'for engineer' do
    let(:user) { engineer }

    permissions :overview? do
      it 'grants access' do
        expect(subject).to permit(user, nil)
      end
    end

  end
end
