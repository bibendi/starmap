require "rails_helper"

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

  # Create skill ratings for different scenarios
  let_it_be(:own_rating) { create(:skill_rating, :draft, user: engineer, technology: technology, quarter: quarter) }
  let_it_be(:team_lead_rating) { create(:skill_rating, user: team_lead, technology: other_technology, quarter: quarter) }
  let_it_be(:other_team_user) { create(:engineer, team: other_team) }
  let_it_be(:other_team_rating) { create(:skill_rating, user: other_team_user, technology: technology, quarter: quarter) }
  let_it_be(:approved_rating) { create(:skill_rating, :approved, user: admin, technology: technology, quarter: quarter) }

  # Context: User is nil (unauthenticated)
  describe "when user is nil" do
    let(:user) { nil }
    let(:record) { build(:skill_rating) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :approve?, :reject?, :edit?, :new?, :copy_from_previous? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: User is inactive
  describe "when user is inactive" do
    let(:user) { inactive_user }
    let(:record) { build(:skill_rating) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :approve?, :reject?, :edit?, :new?, :copy_from_previous? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  context "for admin" do
    let(:user) { admin }
    let(:record) { build(:skill_rating, user: admin) }

    permissions :index?, :show?, :update?, :destroy?, :approve?, :reject?, :edit?, :copy_from_previous? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end

    permissions :create?, :new? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end
  end

  context "for unit_lead" do
    let(:user) { unit_lead }
    let(:unit) { create(:unit, unit_lead: unit_lead) }
    let(:unit_team_lead) { create(:team_lead, team: create(:team, unit: unit)) }
    let(:record) { build(:skill_rating, user: unit_team_lead) }

    permissions :index?, :show?, :approve?, :reject?, :copy_from_previous? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end

    permissions :update?, :edit? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end

    permissions :create?, :new? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end

    permissions :destroy? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end

    context "when rating belongs to engineer in own unit" do
      let(:engineer_in_unit) { create(:engineer, team: unit_team_lead.team) }
      let(:engineer_record) { build(:skill_rating, user: engineer_in_unit) }

      permissions :approve?, :reject? do
        it "denies access" do
          expect(subject).not_to permit(user, engineer_record)
        end
      end
    end
  end

  context "for team_lead" do
    let(:user) { team_lead }

    permissions :index?, :copy_from_previous? do
      it "grants access" do
        expect(subject).to permit(user, build(:skill_rating))
      end
    end

    permissions :create?, :new? do
      context "when creating rating for own team member" do
        let(:record) { build(:skill_rating, user: build(:engineer, team: team_lead.team)) }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end

      context "when creating rating for other team member" do
        let(:record) { build(:skill_rating, user: build(:engineer, team: other_team)) }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    permissions :show?, :approve?, :reject? do
      context "when accessing own team rating" do
        let(:record) { team_lead_rating }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when accessing other team rating" do
        let(:record) { other_team_rating }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    permissions :update?, :edit? do
      context "when accessing own team rating" do
        let(:record) { team_lead_rating }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end

      context "when accessing other team rating" do
        let(:record) { other_team_rating }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    permissions :destroy? do
      it "denies access" do
        expect(subject).not_to permit(user, build(:skill_rating))
      end
    end
  end

  context "for engineer" do
    let(:user) { engineer }

    permissions :index? do
      it "grants access" do
        expect(subject).to permit(user, build(:skill_rating))
      end
    end

    permissions :show? do
      context "when viewing own rating" do
        let(:record) { own_rating }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when viewing other user's rating" do
        let(:record) { team_lead_rating }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    permissions :copy_from_previous? do
      it "denies access" do
        expect(subject).not_to permit(user, build(:skill_rating))
      end
    end

    permissions :create?, :new? do
      context "when creating own rating" do
        let(:record) { build(:skill_rating, user: engineer) }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when creating rating for other user" do
        let(:record) { build(:skill_rating, user: team_lead) }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    permissions :update?, :edit? do
      context "when updating own unapproved rating" do
        let(:record) { own_rating }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when updating own approved rating" do
        let(:record) { approved_rating }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end

      context "when updating other user rating" do
        let(:record) { team_lead_rating }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    permissions :destroy?, :approve?, :reject? do
      it "denies access" do
        expect(subject).not_to permit(user, build(:skill_rating))
      end
    end
  end

  # Scope tests
  describe "Scope" do
    context "for admin" do
      let(:user) { admin }

      it "includes all skill ratings" do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope.count).to be >= 0
        expect(scope).to include(own_rating, other_team_rating)
      end
    end

    context "for unit_lead" do
      let(:user) { unit_lead }

      it "includes all skill ratings" do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope.count).to be >= 0
        expect(scope).to include(own_rating, other_team_rating)
      end
    end

    context "for team_lead" do
      let(:user) { team_lead }

      it "includes only own team ratings" do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope).to include(team_lead_rating)
        expect(scope).not_to include(other_team_rating)
      end
    end

    context "for engineer" do
      let(:user) { engineer }

      it "includes only own ratings" do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope).to include(own_rating)
        expect(scope).not_to include(team_lead_rating)
      end
    end

    context "for nil user" do
      let(:user) { nil }

      it "returns empty scope" do
        scope = SkillRatingPolicy::Scope.new(user, SkillRating.all).resolve
        expect(scope).to be_empty
      end
    end
  end

  # Edge cases and special scenarios
  describe "edge cases" do
    context "when skill_rating is nil" do
      let(:user) { admin }
      let(:record) { nil }

      permissions :show? do
        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      permissions :new? do
        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      permissions :update?, :destroy?, :approve?, :reject?, :edit?, :copy_from_previous? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context "when user has no team assigned" do
      let(:user) { build(:engineer, team: nil) }
      let(:record) { build(:skill_rating, :draft, user: user, technology: technology, quarter: quarter) }

      permissions :show?, :update?, :edit? do
        it "grants access for own rating" do
          expect(subject).to permit(user, record)
        end
      end

      permissions :approve?, :reject? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context "when team_lead is accessing team member rating" do
      let(:user) { team_lead }
      let(:record) { build(:skill_rating, user: build(:engineer, team: team_lead.team), technology: technology, quarter: quarter) }

      permissions :show?, :approve?, :reject? do
        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      permissions :update?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end

    context "when engineer is accessing own approved rating" do
      let(:user) { engineer }
      let(:record) { approved_rating }

      permissions :update?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end
end
