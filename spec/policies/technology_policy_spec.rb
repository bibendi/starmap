require "rails_helper"

# RSpec tests for TechnologyPolicy
# Tests all role-based access control scenarios
RSpec.describe TechnologyPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }

  let(:technology) { build(:technology) }

  # Context: User is nil (unauthenticated)
  describe "when user is nil" do
    let(:user) { nil }
    let(:record) { technology }

    permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit?, :manage_criticality?, :view_technology_metrics?, :bulk_update? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: User is inactive
  describe "when user is inactive" do
    let(:user) { inactive_user }
    let(:record) { technology }

    permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit?, :manage_criticality?, :view_technology_metrics?, :bulk_update? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Context: Role-based access control
  context "for admin" do
    let(:user) { admin }
    let(:record) { technology }

    permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit?, :manage_criticality?, :view_technology_metrics?, :bulk_update? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end
  end

  context "for unit_lead" do
    let(:user) { unit_lead }
    let(:record) { technology }

    permissions :index?, :show?, :create?, :update?, :new?, :edit?, :manage_criticality?, :view_technology_metrics?, :bulk_update? do
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
    let(:record) { technology }

    permissions :index?, :show?, :view_technology_metrics? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end

    permissions :create?, :update?, :destroy?, :new?, :edit?, :manage_criticality?, :bulk_update? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  context "for engineer" do
    let(:user) { engineer }
    let(:record) { technology }

    permissions :index?, :show?, :view_technology_metrics? do
      it "grants access" do
        expect(subject).to permit(user, record)
      end
    end

    permissions :create?, :update?, :destroy?, :new?, :edit?, :manage_criticality?, :bulk_update? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  # Scope tests
  describe "Scope" do
    let_it_be(:technology1) { create(:technology) }
    let_it_be(:technology2) { create(:technology) }

    context "for admin" do
      let(:user) { admin }

      it "includes all technologies" do
        scope = TechnologyPolicy::Scope.new(user, Technology.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(technology1, technology2)
      end
    end

    context "for unit_lead" do
      let(:user) { unit_lead }

      it "includes all technologies" do
        scope = TechnologyPolicy::Scope.new(user, Technology.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(technology1, technology2)
      end
    end

    context "for team_lead" do
      let(:user) { team_lead }

      it "includes all technologies" do
        scope = TechnologyPolicy::Scope.new(user, Technology.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(technology1, technology2)
      end
    end

    context "for engineer" do
      let(:user) { engineer }

      it "includes all technologies" do
        scope = TechnologyPolicy::Scope.new(user, Technology.all).resolve
        expect(scope.count).to be > 0
        expect(scope).to include(technology1, technology2)
      end
    end

    context "for nil user" do
      let(:user) { nil }

      it "returns empty scope" do
        scope = TechnologyPolicy::Scope.new(user, Technology.all).resolve
        expect(scope).to be_empty
      end
    end

    context "for inactive user" do
      let(:user) { inactive_user }

      it "returns empty scope" do
        scope = TechnologyPolicy::Scope.new(user, Technology.all).resolve
        expect(scope).to be_empty
      end
    end
  end

  # Edge cases and special scenarios
  describe "edge cases" do
    context "when record is nil" do
      let(:user) { admin }
      let(:record) { nil }

      permissions :show?, :update?, :destroy?, :edit?, :manage_criticality?, :bulk_update? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end

      permissions :view_technology_metrics? do
        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end
    end

    context "when technology has different criticality levels" do
      let(:user) { unit_lead }

      context "with high criticality technology" do
        let(:record) { build(:technology, :high_criticality) }

        permissions :index?, :show?, :create?, :update?, :new?, :edit?, :manage_criticality?, :view_technology_metrics?, :bulk_update? do
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

      context "with low criticality technology" do
        let(:record) { build(:technology, :low_criticality) }

        permissions :index?, :show?, :create?, :update?, :new?, :edit?, :manage_criticality?, :view_technology_metrics?, :bulk_update? do
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
    end
  end
end
