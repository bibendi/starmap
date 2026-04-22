# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoverageIndexHistoryPolicy, type: :policy do
  subject { described_class }

  let_it_be(:unit) { create(:unit) }
  let_it_be(:team) { create(:team, unit: unit) }
  let_it_be(:other_team) { create(:team) }

  context "for admin" do
    let(:user) { create(:admin) }

    permissions :index? do
      it "allows access to any team" do
        expect(subject).to permit(user, Team.where(id: [team.id, other_team.id]))
      end
    end
  end

  context "for unit_lead" do
    let(:user) { create(:unit_lead) }
    let(:user_unit) { create(:unit, unit_lead: user) }
    let(:unit_team) { create(:team, unit: user_unit) }

    permissions :index? do
      it "allows access to teams in their unit" do
        expect(subject).to permit(user, Team.where(id: [unit_team.id]))
      end

      it "denies access to teams outside their unit" do
        expect(subject).not_to permit(user, Team.where(id: [other_team.id]))
      end
    end
  end

  context "for team_lead" do
    let(:user) { create(:team_lead, team: team) }

    permissions :index? do
      it "allows access to own team" do
        expect(subject).to permit(user, Team.where(id: [team.id]))
      end

      it "denies access to other teams" do
        expect(subject).not_to permit(user, Team.where(id: [other_team.id]))
      end
    end
  end

  context "for engineer" do
    let(:user) { create(:engineer, team: team) }

    permissions :index? do
      it "allows access to own team" do
        expect(subject).to permit(user, Team.where(id: [team.id]))
      end

      it "denies access to other teams" do
        expect(subject).not_to permit(user, Team.where(id: [other_team.id]))
      end
    end
  end

  context "for unauthenticated user" do
    let(:user) { nil }

    permissions :index? do
      it "denies access" do
        expect(subject).not_to permit(user, Team.where(id: [team.id]))
      end
    end
  end
end
