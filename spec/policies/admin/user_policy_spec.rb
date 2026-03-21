require "rails_helper"

RSpec.describe Admin::UserPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }

  let(:record) { build(:user) }

  describe "Admin::UserPolicy" do
    context "for admin" do
      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "grants access" do
          expect(subject).to permit(admin, record)
        end
      end

      it "returns all users in scope" do
        scope = Admin::UserPolicy::Scope.new(admin, User.all).resolve
        expect(scope.count).to be > 0
      end
    end

    context "for unit_lead" do
      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(unit_lead, record)
        end
      end

      it "returns empty scope" do
        scope = Admin::UserPolicy::Scope.new(unit_lead, User.all).resolve
        expect(scope).to be_empty
      end
    end

    context "for team_lead" do
      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(team_lead, record)
        end
      end
    end

    context "for engineer" do
      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(engineer, record)
        end
      end
    end

    context "for nil user" do
      let(:user) { nil }

      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end
    end
  end
end
