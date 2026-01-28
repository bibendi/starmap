require "rails_helper"

# RSpec tests for NavigationPolicy
# Tests all role-based access control scenarios for navigation permissions
RSpec.describe NavigationPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }

  # Context: User is nil (unauthenticated)
  describe "when user is nil" do
    let(:user) { nil }

    permissions :show_admin?, :show_personal_dashboard?, :show_unit? do
      it "denies access" do
        expect(subject).not_to permit(user, nil)
      end
    end
  end

  # Context: User is inactive
  describe "when user is inactive" do
    let(:user) { inactive_user }

    permissions :show_admin?, :show_personal_dashboard?, :show_unit? do
      it "denies access" do
        expect(subject).not_to permit(user, nil)
      end
    end
  end

  # Context: Role-based access control
  context "for admin" do
    let(:user) { admin }

    permissions :show_admin?, :show_personal_dashboard?, :show_unit? do
      it "grants access" do
        expect(subject).to permit(user, nil)
      end
    end
  end

  context "for unit_lead" do
    let(:user) { unit_lead }

    permissions :show_personal_dashboard?, :show_unit? do
      it "grants access" do
        expect(subject).to permit(user, nil)
      end
    end

    permissions :show_admin? do
      it "denies access" do
        expect(subject).not_to permit(user, nil)
      end
    end
  end

  context "for team_lead" do
    let(:user) { team_lead }

    permissions :show_personal_dashboard? do
      it "grants access" do
        expect(subject).to permit(user, nil)
      end
    end

    permissions :show_admin?, :show_unit? do
      it "denies access" do
        expect(subject).not_to permit(user, nil)
      end
    end
  end

  context "for engineer" do
    let(:user) { engineer }

    permissions :show_personal_dashboard? do
      it "grants access" do
        expect(subject).to permit(user, nil)
      end
    end

    permissions :show_admin?, :show_unit? do
      it "denies access" do
        expect(subject).not_to permit(user, nil)
      end
    end
  end
end
