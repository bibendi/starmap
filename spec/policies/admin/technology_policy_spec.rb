require "rails_helper"

RSpec.describe Admin::TechnologyPolicy, type: :policy do
  subject { described_class }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer) }

  let(:record) { build(:technology) }

  describe "Admin::TechnologyPolicy" do
    context "for admin" do
      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "grants access" do
          expect(subject).to permit(admin, record)
        end
      end

      it "returns all technologies in scope" do
        create_list(:technology, 3)
        scope = Admin::TechnologyPolicy::Scope.new(admin, Technology.all).resolve
        expect(scope.count).to eq(3)
      end
    end

    context "for unit_lead" do
      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "grants access" do
          expect(subject).to permit(unit_lead, record)
        end
      end

      it "returns all technologies in scope" do
        create_list(:technology, 3)
        scope = Admin::TechnologyPolicy::Scope.new(unit_lead, Technology.all).resolve
        expect(scope.count).to eq(3)
      end
    end

    context "for team_lead" do
      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(team_lead, record)
        end
      end

      it "returns empty scope" do
        scope = Admin::TechnologyPolicy::Scope.new(team_lead, Technology.all).resolve
        expect(scope).to be_empty
      end
    end

    context "for engineer" do
      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(engineer, record)
        end
      end

      it "returns empty scope" do
        scope = Admin::TechnologyPolicy::Scope.new(engineer, Technology.all).resolve
        expect(scope).to be_empty
      end
    end

    context "for nil user" do
      let(:user) { nil }

      permissions :index?, :show?, :create?, :update?, :destroy?, :new?, :edit? do
        it "denies access" do
          expect(subject).not_to permit(user, record)
        end
      end

      it "returns empty scope" do
        scope = Admin::TechnologyPolicy::Scope.new(nil, Technology.all).resolve
        expect(scope).to be_empty
      end
    end
  end
end
