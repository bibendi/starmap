require "rails_helper"

RSpec.describe DashboardPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }

  describe "when user is nil" do
    let(:user) { nil }

    permissions :overview?, :personal? do
      it "denies access" do
        expect(subject).not_to permit(user, nil)
      end
    end
  end

  describe "when user is inactive" do
    let(:user) { inactive_user }

    permissions :overview?, :personal? do
      it "denies access" do
        expect(subject).not_to permit(user, nil)
      end
    end
  end

  context "for admin" do
    let(:user) { admin }

    permissions :overview?, :personal? do
      it "grants access" do
        expect(subject).to permit(user, nil)
      end
    end
  end

  context "for unit_lead" do
    let(:user) { unit_lead }

    permissions :overview?, :personal? do
      it "grants access" do
        expect(subject).to permit(user, nil)
      end
    end
  end

  context "for team_lead" do
    let(:user) { team_lead }

    permissions :personal? do
      context "when viewing their own dashboard" do
        it "grants access" do
          expect(subject).to permit(user, user)
        end
      end

      context "when viewing team member dashboard" do
        it "grants access" do
          expect(subject).to permit(user, build(:engineer, team: team_lead.team))
        end
      end

      context "when viewing user from different team" do
        it "grants access" do
          expect(subject).to permit(user, build(:engineer))
        end
      end
    end
  end

  context "for engineer" do
    let(:user) { engineer }

    permissions :overview? do
      it "grants access" do
        expect(subject).to permit(user, nil)
      end
    end
  end
end
