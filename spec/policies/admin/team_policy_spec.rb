require "rails_helper"

RSpec.describe Admin::TeamPolicy, type: :policy do
  subject { described_class }

  let(:admin) { create(:user, role: "admin", team: nil) }
  let(:engineer) { create(:engineer) }
  let(:team) { create(:team) }

  permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
    it "grants access to admin" do
      expect(subject).to permit(admin, [:admin, team])
    end

    it "denies access to non-admin" do
      expect(subject).not_to permit(engineer, [:admin, team])
    end
  end

  describe "Scope" do
    it "returns all teams for admin" do
      create_list(:team, 3)
      scope = described_class::Scope.new(create(:user, role: "admin", team: nil), Team.all)
      total = Team.count
      expect(scope.resolve.count).to eq(total)
    end

    it "returns none for non-admin" do
      create_list(:team, 3)
      scope = described_class::Scope.new(engineer, Team.all)
      expect(scope.resolve.count).to eq(0)
    end
  end
end
