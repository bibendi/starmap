require "rails_helper"

# RSpec tests for QuarterPolicy
# Tests all role-based access control scenarios for quarters
RSpec.describe QuarterPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }

  # Context: User is nil (unauthenticated)
  describe "when user is nil" do
    let(:user) { nil }
    let(:record) { build(:quarter) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :edit?, :new?, :activate?, :close?, :copy_ratings?, :view_current?, :view_historical? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: User is inactive
  describe "when user is inactive" do
    let(:user) { inactive_user }
    let(:record) { build(:quarter) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :edit?, :new?, :activate?, :close?, :copy_ratings?, :view_current?, :view_historical? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: Role-based access control
  context "for admin" do
    let(:user) { admin }
    let(:record) { build(:quarter) }

    permissions :index?, :show?, :create?, :update?, :destroy?, :edit?, :new?, :activate?, :close?, :copy_ratings?, :view_current?, :view_historical? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end
  end

  context "for unit_lead" do
    let(:user) { unit_lead }
    let(:record) { build(:quarter) }

    permissions :index?, :show?, :create?, :update?, :edit?, :new?, :activate?, :close?, :copy_ratings?, :view_current?, :view_historical? do
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
    let(:record) { build(:quarter) }

    permissions :index?, :show?, :view_current?, :view_historical?, :copy_ratings? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end

    permissions :create?, :update?, :destroy?, :edit?, :new?, :activate?, :close? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  context "for engineer" do
    let(:user) { engineer }
    let(:record) { build(:quarter) }

    permissions :index?, :show?, :view_current?, :view_historical? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end

    permissions :create?, :update?, :destroy?, :edit?, :new?, :activate?, :close?, :copy_ratings? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Scope tests
  describe "Scope" do
    let_it_be(:quarter1) { create(:quarter) }
    let_it_be(:quarter2) { create(:quarter) }

    context "for admin" do
      let(:user) { admin }

      it "includes all quarters" do
        scope = QuarterPolicy::Scope.new(user, Quarter.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(quarter1, quarter2)
      end
    end

    context "for unit_lead" do
      let(:user) { unit_lead }

      it "includes all quarters" do
        scope = QuarterPolicy::Scope.new(user, Quarter.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(quarter1, quarter2)
      end
    end

    context "for team_lead" do
      let(:user) { team_lead }

      it "includes all quarters" do
        scope = QuarterPolicy::Scope.new(user, Quarter.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(quarter1, quarter2)
      end
    end

    context "for engineer" do
      let(:user) { engineer }

      it "includes all quarters" do
        scope = QuarterPolicy::Scope.new(user, Quarter.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(quarter1, quarter2)
      end
    end

    context "for nil user" do
      let(:user) { nil }

      it "returns empty scope" do
        scope = QuarterPolicy::Scope.new(user, Quarter.all).resolve
        expect(scope).to be_empty
      end
    end

    context "for inactive user" do
      let(:user) { inactive_user }

      it "returns empty scope" do
        scope = QuarterPolicy::Scope.new(user, Quarter.all).resolve
        expect(scope).to be_empty
      end
    end
  end

  # Edge cases and special scenarios
  describe "edge cases" do
    context "when record is nil" do
      let(:user) { admin }
      let(:record) { nil }

      permissions :index?, :create?, :new?, :view_current?, :view_historical? do
        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      permissions :show?, :update?, :destroy?, :edit?, :activate?, :close?, :copy_ratings? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end
end
