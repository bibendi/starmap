require "rails_helper"

RSpec.describe Admin::UnitPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:user, role: "admin", team: nil) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:unit) { create(:unit) }

  permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
    it "grants access to admin" do
      expect(subject).to permit(admin, [:admin, unit])
    end

    it "denies access to non-admin" do
      expect(subject).not_to permit(engineer, [:admin, unit])
    end
  end

  describe "Scope" do
    it "returns all units for admin" do
      create_list(:unit, 3)
      scope = described_class::Scope.new(admin, Unit.all)
      total = Unit.count
      expect(scope.resolve.count).to eq(total)
    end

    it "returns none for non-admin" do
      create_list(:unit, 3)
      scope = described_class::Scope.new(engineer, Unit.all)
      expect(scope.resolve.count).to eq(0)
    end
  end
end
