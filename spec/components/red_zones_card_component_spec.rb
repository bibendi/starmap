# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedZonesCardComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  describe "#calculate" do
    context "when technologies have sufficient experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: 'high')
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns 0 red zones" do
        component = described_class.new(team: team)
        expect(component.red_zones_count).to eq(0)
      end
    end

    context "when technologies have insufficient experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: 'high')
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 1 red zone" do
        component = described_class.new(team: team)
        expect(component.red_zones_count).to eq(1)
      end
    end

    context "when team has no technologies" do
      let(:empty_team) { create(:team) }

      it "returns 0 red zones" do
        component = described_class.new(team: empty_team)
        expect(component.red_zones_count).to eq(0)
      end
    end

    context "when technology has low criticality" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: 'low')
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "does not count low criticality technologies" do
        component = described_class.new(team: team)
        expect(component.red_zones_count).to eq(0)
      end
    end

    context "when there is no current quarter" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        Quarter.destroy_all
      end

      it "returns 0 red zones" do
        component = described_class.new(team: team)
        expect(component.red_zones_count).to eq(0)
      end
    end

    context "with custom target_experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 1)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: 'high')
      end

      it "calculates based on custom target" do
        component = described_class.new(team: team)
        expect(component.red_zones_count).to eq(1)
      end
    end
  end

  describe "rendering" do
    context "with custom label and description" do
      it "renders custom text" do
        component = described_class.new(team: team, label: "Custom Label", description: "Custom Description")
        render_inline(component)
        expect(page).to have_text("Custom Label")
        expect(page).to have_text("Custom Description")
      end
    end

    context "with default label and description" do
      it "renders default text" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Red Zones")
        expect(page).to have_text("Важные технологии без покрытия")
      end
    end

    context "red zones count display" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: 'high')
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "displays count" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("2")
      end
    end

    context "when count is 0" do
      it "displays 0" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("0")
      end
    end
  end
end
