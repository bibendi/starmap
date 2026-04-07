require "rails_helper"

RSpec.describe UnitPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:inactive_user) { create(:inactive_user) }
  let_it_be(:unit_lead_without_unit) { create(:unit_lead) }
  let_it_be(:other_unit_lead) { create(:unit_lead) }

  let_it_be(:unit) { create(:unit, unit_lead: unit_lead) }
  let_it_be(:other_unit) { create(:unit) }
  let_it_be(:unit_without_lead) { create(:unit, unit_lead: nil) }
  let_it_be(:other_unit_with_lead) { create(:unit, unit_lead: other_unit_lead) }

  describe "when user is nil" do
    let(:user) { nil }
    let(:record) { unit }

    permissions :show? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  describe "when user is inactive" do
    let(:user) { inactive_user }
    let(:record) { unit }

    permissions :show? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  context "for admin" do
    let(:user) { admin }

    permissions :show? do
      it "grants access to any unit" do
        expect(subject).to permit(user, unit)
        expect(subject).to permit(user, other_unit)
        expect(subject).to permit(user, unit_without_lead)
      end

      it "denies access to new (unpersisted) unit" do
        expect(subject).not_to permit(user, Unit.new)
      end
    end
  end

  context "for unit_lead" do
    let(:user) { unit_lead }

    permissions :show? do
      it "grants access to their own unit" do
        expect(subject).to permit(user, unit)
      end

      it "denies access to other unit" do
        expect(subject).not_to permit(user, other_unit)
      end

      it "denies access to unit without lead" do
        expect(subject).not_to permit(user, unit_without_lead)
      end

      it "denies access to new (unpersisted) unit" do
        expect(subject).not_to permit(user, Unit.new)
      end

      context "when unit_lead has no unit assigned" do
        let(:user) { unit_lead_without_unit }

        it "denies access to any unit" do
          expect(subject).not_to permit(user, unit)
          expect(subject).not_to permit(user, other_unit)
          expect(subject).not_to permit(user, unit_without_lead)
        end
      end
    end
  end

  context "for team_lead" do
    let(:user) { team_lead }
    let(:record) { unit }

    permissions :show? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  context "for engineer" do
    let(:user) { engineer }
    let(:record) { unit }

    permissions :show? do
      it "denies access" do
        expect(subject).not_to permit(user, record)
      end
    end
  end

  describe "scope" do
    context "when user is admin" do
      let(:user) { admin }

      it "returns all units" do
        result = UnitPolicy::Scope.new(user, Unit.all).resolve
        expect(result).to include(unit, other_unit, other_unit_with_lead, unit_without_lead)
      end
    end

    context "when user is unit_lead" do
      let(:user) { unit_lead }

      it "returns only their unit" do
        result = UnitPolicy::Scope.new(user, Unit.all).resolve
        expect(result).to contain_exactly(unit)
        expect(result).not_to include(other_unit, other_unit_with_lead, unit_without_lead)
      end

      context "when unit_lead has no unit assigned" do
        let(:user) { unit_lead_without_unit }

        it "returns empty scope" do
          result = UnitPolicy::Scope.new(user, Unit.all).resolve
          expect(result).to be_empty
        end
      end
    end

    context "when user is team_lead" do
      let(:user) { team_lead }

      it "returns empty scope" do
        result = UnitPolicy::Scope.new(user, Unit.all).resolve
        expect(result).to be_empty
      end
    end

    context "when user is engineer" do
      let(:user) { engineer }

      it "returns empty scope" do
        result = UnitPolicy::Scope.new(user, Unit.all).resolve
        expect(result).to be_empty
      end
    end

    context "when user is nil" do
      let(:user) { nil }

      it "returns empty scope" do
        result = UnitPolicy::Scope.new(user, Unit.all).resolve
        expect(result).to be_empty
      end
    end
  end
end
