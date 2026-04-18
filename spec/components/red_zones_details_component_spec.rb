# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedZonesDetailsComponent, type: :component do
  let_it_be(:team) { create(:team) }
  let_it_be(:team2) { create(:team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology3) { create(:technology) }

  describe "#any_red_zones?" do
    it "returns true when red zones exist" do
      component = described_class.new(teams: [team], red_zones_data: [
        {technology: technology1, team: team, expert_count: 0, target_experts: 2, deficit: 2, experts: []}
      ])
      expect(component.any_red_zones?).to be true
    end

    it "returns false when no red zones" do
      component = described_class.new(teams: [team], red_zones_data: [])
      expect(component.any_red_zones?).to be false
    end
  end

  describe "#grouped_red_zones" do
    context "with single team" do
      it "returns flat array" do
        data = [{technology: technology1, team: team, expert_count: 0, target_experts: 2, deficit: 2, experts: []}]
        component = described_class.new(teams: [team], red_zones_data: data)
        expect(component.grouped_red_zones).to be_an(Array)
        expect(component.grouped_red_zones.size).to eq(1)
      end
    end

    context "with multiple teams" do
      it "returns hash grouped by technology" do
        data = [
          {technology: technology1, team: team, expert_count: 0, target_experts: 2, deficit: 2, experts: []},
          {technology: technology1, team: team2, expert_count: 0, target_experts: 2, deficit: 2, experts: []}
        ]
        component = described_class.new(teams: [team, team2], red_zones_data: data)
        grouped = component.grouped_red_zones
        expect(grouped).to be_a(Hash)
        expect(grouped.keys).to eq([technology1])
        expect(grouped[technology1].size).to eq(2)
        expect(grouped[technology1].pluck(:team)).to contain_exactly(team, team2)
      end
    end
  end

  describe "rendering" do
    context "when there are red zones" do
      context "with single team" do
        it "renders red zones list" do
          data = [{technology: technology1, team: team, expert_count: 0, target_experts: 2, deficit: 2, experts: []}]
          component = described_class.new(teams: [team], red_zones_data: data)
          render_inline(component)

          expect(page).to have_text("Red Zones")
          expect(page).to have_text(/critical coverage gaps/i)
          expect(page).to have_text(technology1.name)
          expect(page).to have_text("0/2")
        end
      end

      context "with multiple teams" do
        it "renders grouped red zones with team links" do
          data = [
            {technology: technology3, team: team, expert_count: 0, target_experts: 2, deficit: 2, experts: []},
            {technology: technology3, team: team2, expert_count: 0, target_experts: 2, deficit: 2, experts: []}
          ]
          component = described_class.new(teams: [team, team2], red_zones_data: data)
          render_inline(component)

          expect(page).to have_text("Red Zones")
          expect(page).to have_text(/critical coverage gaps/i)
          expect(page).to have_text(technology3.name, count: 1)
          expect(page).to have_text(team.name)
          expect(page).to have_text(team2.name)
          expect(page).to have_text("0/2", count: 2)
          expect(page).to have_link(team.name)
          expect(page).to have_link(team2.name)
        end
      end
    end

    context "when there are no red zones" do
      it "renders empty state message" do
        component = described_class.new(teams: [team], red_zones_data: [])
        render_inline(component)

        expect(page).to have_text("Red Zones")
        expect(page).to have_text("No red zones detected")
      end
    end
  end
end
