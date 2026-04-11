require "rails_helper"

RSpec.describe TeamTechnologyPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team) { create(:team) }
  let_it_be(:team_lead) { create(:team_lead, team: team) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:other_team) { create(:team) }
  let_it_be(:other_team_lead) { create(:team_lead) }
  let_it_be(:other_engineer) { create(:engineer, team: other_team) }
  let_it_be(:inactive_user) { create(:inactive_user) }

  permissions :show? do
    context "when user is nil" do
      let(:user) { nil }
      let(:record) { team }

      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end

    context "when user is inactive" do
      let(:user) { inactive_user }
      let(:record) { team }

      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end

    context "for admin" do
      let(:user) { admin }

      it "grants access to any team" do
        expect(subject).to permit(user, team)
        expect(subject).to permit(user, other_team)
      end
    end

    context "for unit_lead" do
      let(:user) { unit_lead }

      it "grants access to any team" do
        expect(subject).to permit(user, team)
        expect(subject).to permit(user, other_team)
      end
    end

    context "for team_lead" do
      let(:user) { team_lead }

      it "grants access to own team" do
        expect(subject).to permit(user, team)
      end

      it "denies access to other team" do
        expect(subject).not_to permit(user, other_team)
      end
    end

    context "for engineer" do
      let(:user) { engineer }

      it "denies access to own team" do
        expect(subject).not_to permit(user, team)
      end

      it "denies access to other team" do
        expect(subject).not_to permit(user, other_team)
      end
    end

    context "when team is nil" do
      let(:user) { admin }
      let(:record) { nil }

      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end
end
