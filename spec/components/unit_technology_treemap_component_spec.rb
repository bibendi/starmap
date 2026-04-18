# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnitTechnologyTreemapComponent, type: :component do
  let_it_be(:team) { create(:team) }
  let_it_be(:technology1) { create(:technology, name: "Ruby") }
  let_it_be(:technology2) { create(:technology, name: "React") }

  describe "#intensity_for_experts" do
    it "returns normalized intensity" do
      data = [
        {technology: technology1, expert_count: 2, all_teams_in_target: true, deficit: 0},
        {technology: technology2, expert_count: 1, all_teams_in_target: false, deficit: 1}
      ]
      component = described_class.new(teams: [team], technologies_data: data)
      expect(component.intensity_for_experts(1)).to eq(3)
      expect(component.intensity_for_experts(2)).to eq(5)
    end
  end

  describe "#chart_data" do
    it "returns chart data for each technology" do
      data = [
        {technology: technology1, expert_count: 2, all_teams_in_target: true, deficit: 0},
        {technology: technology2, expert_count: 1, all_teams_in_target: false, deficit: 1}
      ]
      component = described_class.new(teams: [team], technologies_data: data)
      chart = component.chart_data
      expect(chart.size).to eq(2)
      expect(chart).to all(include(:name, :category, :value, :allTeamsInTarget, :intensity, :deficitIntensity))
    end
  end

  describe "rendering" do
    context "when there are technologies with experts" do
      let(:data) do
        [{technology: technology1, expert_count: 1, all_teams_in_target: false, deficit: 1}]
      end

      it "renders the treemap chart container" do
        component = described_class.new(teams: [team], technologies_data: data)
        render_inline(component)
        expect(page).to have_css(".treemap-chart-container")
        expect(page).to have_css("canvas[data-controller='treemap-chart']")
      end
    end

    context "when there are no technologies" do
      it "renders no data message" do
        component = described_class.new(teams: [team], technologies_data: [])
        render_inline(component)
        expect(page).to have_css(".text-muted--center")
      end
    end
  end
end
