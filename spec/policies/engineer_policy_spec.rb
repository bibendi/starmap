require "rails_helper"

RSpec.describe EngineerPolicy, type: :policy do
  subject { described_class }

  let_it_be(:unit) { create(:unit) }
  let_it_be(:team) { create(:team, unit: unit) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead, team: team) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:other_team) { create(:team) }
  let_it_be(:other_engineer) { create(:engineer, team: other_team) }
  let_it_be(:inactive_user) { create(:engineer, active: false) }

  before do
    unit.update(unit_lead: unit_lead)
  end

  describe "when user is nil" do
    let(:user) { nil }
    let(:record) { engineer }

    permissions :show? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  describe "when user is inactive" do
    let(:user) { inactive_user }
    let(:record) { engineer }

    permissions :show? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  context "for admin" do
    let(:user) { admin }

    permissions :show? do
      it "grants access to any engineer" do
        expect(subject).to permit(user, engineer)
        expect(subject).to permit(user, other_engineer)
      end
    end
  end

  context "for unit_lead" do
    let(:user) { unit_lead }

    permissions :show? do
      context "when engineer is from unit_lead's unit" do
        let(:record) { engineer }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when engineer is from other unit" do
        let(:record) { other_engineer }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  context "for team_lead" do
    let(:user) { team_lead }

    permissions :show? do
      context "when engineer is from team_lead's team" do
        let(:record) { engineer }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when engineer is from other team" do
        let(:record) { other_engineer }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  context "for engineer" do
    let(:user) { engineer }

    permissions :show? do
      context "when viewing own profile" do
        let(:record) { engineer }

        it "grants access" do
          expect(subject).to permit(user, record)
        end
      end

      context "when viewing other engineer's profile" do
        let(:record) { other_engineer }

        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end

  describe "edge cases" do
    context "when engineer has no team" do
      let(:engineer_without_team) { create(:engineer, team: nil) }
      let(:user) { unit_lead }
      let(:record) { engineer_without_team }

      permissions :show? do
        it "denies access for unit_lead" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end
end
