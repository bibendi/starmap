# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnitTechnologyTreemapComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }
  let_it_be(:technology3) { create(:technology) }

  describe "#technologies_data" do
    context "when there are technologies with experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2)
        create(:team_technology, team: team, technology: technology3, target_experts: 3)

        # Technology1: 2 experts, meets target
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)

        # Technology2: 1 expert, below target
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)

        # Technology3: 3 experts, meets target
        create(:skill_rating, user: user, technology: technology3, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology3, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology3, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns technologies sorted by expert count descending" do
        component = described_class.new(teams: [team])
        expect(component.technologies_data.size).to eq(3)
        expect(component.technologies_data[0][:expert_count]).to eq(3)
        expect(component.technologies_data[1][:expert_count]).to eq(2)
        expect(component.technologies_data[2][:expert_count]).to eq(1)
      end

      it "marks technologies as all_teams_in_target when target is met" do
        component = described_class.new(teams: [team])
        expect(component.technologies_data[0][:all_teams_in_target]).to be true
        expect(component.technologies_data[1][:all_teams_in_target]).to be true
        expect(component.technologies_data[2][:all_teams_in_target]).to be false
      end

      it "calculates deficit for technologies below target" do
        component = described_class.new(teams: [team])
        expect(component.technologies_data[0][:deficit]).to eq(0)
        expect(component.technologies_data[1][:deficit]).to eq(0)
        expect(component.technologies_data[2][:deficit]).to eq(1)
      end
    end

    context "when technology has no experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
      end

      it "excludes technologies with zero experts" do
        component = described_class.new(teams: [team])
        expect(component.technologies_data).to be_empty
      end
    end

    context "when there is no current quarter" do
      before do
        Quarter.destroy_all
      end

      it "returns empty array" do
        component = described_class.new(teams: [team])
        expect(component.technologies_data).to be_empty
      end
    end
  end

  describe "#any_technologies?" do
    context "when there are technologies with experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns true" do
        component = described_class.new(teams: [team])
        expect(component.any_technologies?).to be true
      end
    end

    context "when there are no technologies with experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
      end

      it "returns false" do
        component = described_class.new(teams: [team])
        expect(component.any_technologies?).to be false
      end
    end
  end

  describe "#technologies_count" do
    before do
      create(:team_technology, team: team, technology: technology1, target_experts: 2)
      create(:team_technology, team: team, technology: technology2, target_experts: 2)
      create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
    end

    it "returns the count of technologies" do
      component = described_class.new(teams: [team])
      expect(component.technologies_count).to eq(2)
    end
  end

  describe "#intensity_for_experts" do
    before do
      create(:team_technology, team: team, technology: technology1, target_experts: 2)
      create(:team_technology, team: team, technology: technology2, target_experts: 2)
      create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
      create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
    end

    it "returns normalized intensity based on max experts" do
      component = described_class.new(teams: [team])
      expect(component.max_experts).to eq(2)
      expect(component.intensity_for_experts(1)).to eq(3)
      expect(component.intensity_for_experts(2)).to eq(5)
    end
  end

  describe "#intensity_for_deficit" do
    before do
      create(:team_technology, team: team, technology: technology1, target_experts: 3)
      create(:team_technology, team: team, technology: technology2, target_experts: 5)
      create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
    end

    it "returns normalized intensity based on max deficit" do
      component = described_class.new(teams: [team])
      expect(component.max_deficit).to eq(4)
      expect(component.intensity_for_deficit(2)).to eq(3)
      expect(component.intensity_for_deficit(4)).to eq(5)
    end
  end

  describe "#chart_data" do
    context "with multiple technologies" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2)
        create(:team_technology, team: team, technology: technology3, target_experts: 3)

        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology3, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology3, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology3, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns chart data for each technology" do
        component = described_class.new(teams: [team])
        data = component.chart_data

        expect(data.size).to eq(3)

        # Each item should have required keys
        expect(data).to all(
          include(:name, :category, :value, :allTeamsInTarget, :intensity, :deficitIntensity)
        )
      end

      it "includes technology names" do
        component = described_class.new(teams: [team])
        data = component.chart_data

        names = data.pluck(:name)
        expect(names).to include(technology1.name)
        expect(names).to include(technology2.name)
        expect(names).to include(technology3.name)
      end

      it "includes correct expert counts" do
        component = described_class.new(teams: [team])
        data = component.chart_data

        tech3_data = data.find { |d| d[:name] == technology3.name }
        tech1_data = data.find { |d| d[:name] == technology1.name }

        expect(tech3_data[:value]).to eq(3)
        expect(tech1_data[:value]).to eq(2)
      end
    end

    context "with empty technologies" do
      it "returns empty array" do
        component = described_class.new(teams: [team])
        expect(component.chart_data).to be_empty
      end
    end
  end

  describe "rendering" do
    context "when there are technologies with experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "renders the treemap chart container" do
        component = described_class.new(teams: [team])
        render_inline(component)
        expect(page).to have_css(".treemap-chart-container")
        expect(page).to have_css("canvas[data-controller='treemap-chart']")
      end

      it "renders chart data as JSON" do
        component = described_class.new(teams: [team])
        render_inline(component)
        canvas = page.find("canvas[data-controller='treemap-chart']")
        expect(canvas["data-treemap-chart-data-value"]).to be_present
      end
    end

    context "when there are no technologies" do
      it "renders no data message" do
        component = described_class.new(teams: [team])
        render_inline(component)
        expect(page).to have_css(".text-muted--center")
      end
    end

    context "with multiple teams" do
      let_it_be(:team2) { create(:team) }
      let_it_be(:user2) { create(:user, team: team2) }

      before do
        # Technology configured in both teams
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team2, technology: technology1, target_experts: 1)

        # Team1: 1 expert (below target of 2)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)

        # Team2: 0 experts (below target of 1)
        # No skill rating for team2
      end

      it "aggregates experts across all teams" do
        component = described_class.new(teams: [team, team2])
        expect(component.technologies_data.first[:expert_count]).to eq(1)
      end

      it "marks as not all teams in target if any team is below target" do
        component = described_class.new(teams: [team, team2])
        expect(component.technologies_data.first[:all_teams_in_target]).to be false
        expect(component.technologies_data.first[:deficit]).to eq(2) # 1 from team1 + 1 from team2
      end
    end
  end
end
