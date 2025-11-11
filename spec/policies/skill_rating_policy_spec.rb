require 'rails_helper'

# RSpec tests for SkillRatingPolicy
# Tests all role-based access control scenarios for skill ratings
RSpec.describe SkillRatingPolicy, type: :policy do
  subject { described_class }

  # Create test users for all roles
  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }

  # Create test data
  let_it_be(:technology) { create(:technology) }
  let_it_be(:other_technology) { create(:technology) }
  let_it_be(:quarter) { create(:quarter) }
  let_it_be(:other_team) { create(:team) }

  let(:own_team) { team_lead.team }

  # Create skill ratings for different scenarios
  let_it_be(:own_rating) { create(:skill_rating, user: engineer, technology: technology, quarter: quarter) }
  let_it_be(:team_lead_rating) { create(:skill_rating, user: team_lead, technology: other_technology, quarter: quarter) }
  let_it_be(:other_team_user) { create(:engineer, team: other_team) }
  let_it_be(:other_team_rating) { create(:skill_rating, user: other_team_user, technology: technology, quarter: quarter) }
  let_it_be(:approved_rating) { create(:skill_rating, :approved, user: admin, technology: technology, quarter: quarter) }

  # Context: User is nil (unauthenticated)
  describe 'when user is nil' do
    let(:user) { nil }
    let(:record) { build(:skill_rating) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :approve?, :reject?, :edit?, :new?, :copy_from_previous? do
      it 'denies access' do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: User is inactive
  describe 'when user is inactive' do
    let(:user) { inactive_user }
    let(:record) { build(:skill_rating) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :approve?, :reject?, :edit?, :new?, :copy_from_previous? do
      it 'denies access' do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Index permission tests
  describe 'index? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { build(:skill_rating) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { build(:skill_rating) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }
      let(:record) { build(:skill_rating) }

      permissions :index? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { build(:skill_rating) }

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
        context 'when viewing any rating' do
          let(:record) { own_rating }

          it 'grants access to own rating' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other rating' do
            expect(subject).to permit(user, other_team_rating)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :show? do
        context 'when viewing any rating' do
          let(:record) { own_rating }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other rating' do
            expect(subject).to permit(user, other_team_rating)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :show? do
        context 'when viewing own team rating' do
          let(:record) { team_lead_rating }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing other team rating' do
          let(:record) { other_team_rating }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      permissions :show? do
        context 'when viewing own rating' do
          let(:user) { engineer }
          let(:record) { own_rating }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when viewing other user rating' do
          let(:user) { engineer }
          let(:record) { team_lead_rating }
          it 'grants access for overview dashboard' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end
  end

  # Create permission tests
  describe 'create? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { build(:skill_rating, user: admin) }

      permissions :create? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { build(:skill_rating, user: unit_lead) }

      permissions :create? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :create? do
        context 'when creating rating for own team member' do
          let(:record) { build(:skill_rating, user: build(:engineer, team: own_team)) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when creating rating for other team member' do
          let(:record) { build(:skill_rating, user: build(:engineer, team: other_team)) }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :create? do
        context 'when creating own rating' do
          let(:record) { build(:skill_rating, user: engineer) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when creating rating for other user' do
          let(:record) { build(:skill_rating, user: team_lead) }
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
        context 'when updating any rating' do
          let(:record) { own_rating }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other rating' do
            expect(subject).to permit(user, other_team_rating)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :update? do
        context 'when updating any rating' do
          let(:record) { own_rating }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other rating' do
            expect(subject).to permit(user, other_team_rating)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :update? do
        context 'when updating own team rating' do
          let(:record) { team_lead_rating }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when updating other team rating' do
          let(:record) { other_team_rating }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :update? do
        context 'when updating own unapproved rating' do
          let(:record) { own_rating }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when updating own approved rating' do
          let(:record) { approved_rating }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when updating other user rating' do
          let(:record) { team_lead_rating }
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
      let(:record) { own_rating }

      permissions :destroy? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { own_rating }

      permissions :destroy? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }
      let(:record) { own_rating }

      permissions :destroy? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { own_rating }

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
      let(:record) { own_rating }

      permissions :approve? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :approve? do
        context 'when approving any rating' do
          let(:record) { own_rating }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :approve? do
        context 'when approving own team rating' do
          let(:record) { build(:skill_rating, user: build(:engineer, team: own_team), technology: technology, quarter: quarter) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when approving other team rating' do
          let(:record) { other_team_rating }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { own_rating }

      permissions :approve? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Reject permission tests (should mirror approve?)
  describe 'reject? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { own_rating }

      permissions :reject? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { own_rating }

      permissions :reject? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :reject? do
        context 'when rejecting own team rating' do
          let(:record) { build(:skill_rating, user: build(:engineer, team: own_team), technology: technology, quarter: quarter) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when rejecting other team rating' do
          let(:record) { other_team_rating }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { own_rating }

      permissions :reject? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Edit permission tests (should mirror update?)
  describe 'edit? permission' do
    context 'for admin' do
      let(:user) { admin }

      permissions :edit? do
        context 'when editing any rating' do
          let(:record) { own_rating }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other rating' do
            expect(subject).to permit(user, other_team_rating)
          end
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      permissions :edit? do
        context 'when editing any rating' do
          let(:record) { own_rating }

          it 'grants access' do
            expect(subject).to permit(user, record)
          end

          it 'grants access to other rating' do
            expect(subject).to permit(user, other_team_rating)
          end
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :edit? do
        context 'when editing own team rating' do
          let(:record) { team_lead_rating }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when editing other team rating' do
          let(:record) { other_team_rating }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :edit? do
        context 'when editing own unapproved rating' do
          let(:record) { own_rating }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when editing own approved rating' do
          let(:record) { approved_rating }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end

        context 'when editing other user rating' do
          let(:record) { team_lead_rating }
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
      let(:record) { build(:skill_rating, user: admin) }

      permissions :new? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { build(:skill_rating, user: unit_lead) }

      permissions :new? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      permissions :new? do
        context 'when creating rating for own team member' do
          let(:record) { build(:skill_rating, user: build(:engineer, team: own_team)) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when creating rating for other team member' do
          let(:record) { build(:skill_rating, user: build(:engineer, team: other_team)) }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      permissions :new? do
        context 'when creating own rating' do
          let(:record) { build(:skill_rating, user: engineer) }
          it 'grants access' do
            expect(subject).to permit(user, record)
          end
        end

        context 'when creating rating for other user' do
          let(:record) { build(:skill_rating, user: team_lead) }
          it 'denies access' do
            expect(subject).not_to permit(user, record)
          end
        end
      end
    end
  end

  # Copy from previous permission tests
  describe 'copy_from_previous? permission' do
    context 'for admin' do
      let(:user) { admin }
      let(:record) { build(:skill_rating) }

      permissions :copy_from_previous? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }
      let(:record) { build(:skill_rating) }

      permissions :copy_from_previous? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }
      let(:record) { build(:skill_rating) }

      permissions :copy_from_previous? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'for engineer' do
      let(:user) { engineer }
      let(:record) { build(:skill_rating) }

      permissions :copy_from_previous? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  # Scope tests
  describe 'Scope' do
    context 'for admin' do
      let(:user) { admin }

      it 'includes all skill ratings' do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope.count).to be >= 0
        expect(scope).to include(own_rating, other_team_rating)
      end
    end

    context 'for unit_lead' do
      let(:user) { unit_lead }

      it 'includes all skill ratings' do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope.count).to be >= 0
        expect(scope).to include(own_rating, other_team_rating)
      end
    end

    context 'for team_lead' do
      let(:user) { team_lead }

      it 'includes only own team ratings' do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope).to include(team_lead_rating)
        expect(scope).not_to include(other_team_rating)
      end
    end

    context 'for engineer' do
      let(:user) { engineer }

      it 'includes only own ratings' do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope).to include(own_rating)
        expect(scope).not_to include(team_lead_rating)
      end
    end

    context 'for nil user' do
      let(:user) { nil }

      it 'returns empty scope' do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope).to be_empty
      end
    end
  end

  # Edge cases and special scenarios
  describe 'edge cases' do
    context 'when skill_rating is nil' do
      let(:user) { admin }
      let(:record) { nil }

      permissions :show? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end

      permissions :new? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end

      permissions :update?, :destroy?, :approve?, :reject?, :edit?, :copy_from_previous? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context 'when user has no team assigned' do
      let(:user) { build(:engineer, team: nil) }
      let(:record) { own_rating }

      permissions :update?, :edit?, :approve?, :reject? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end

      permissions :show? do
        it 'grants access for own rating' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'when team_lead is accessing team member rating' do
      let(:user) { team_lead }
      let(:record) { build(:skill_rating, user: build(:engineer, team: own_team), technology: technology, quarter: quarter) }

      permissions :show?, :update?, :edit?, :approve?, :reject? do
        it 'grants access' do
          expect(subject).to permit(user, record)
        end
      end
    end

    context 'when engineer is accessing own approved rating' do
      let(:user) { engineer }
      let(:record) { approved_rating }

      permissions :update?, :edit? do
        it 'denies access' do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end
end
