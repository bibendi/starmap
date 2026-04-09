# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedZonesDetailsComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:team2) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }
  let_it_be(:user3) { create(:user, team: team) }
  let_it_be(:user_in_team2) { create(:user, team: team2) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }
  let_it_be(:technology3) { create(:technology) }
  let_it_be(:n_plus_one_technologies) { create_list(:technology, 3) }

  describe "#red_zones_data" do
    context "when technologies have sufficient experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user3, technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns empty array" do
        component = described_class.new(teams: [team])
        expect(component.red_zones_data).to be_empty
      end
    end

    context "when there are no red zones" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns false" do
        component = described_class.new(teams: [team])
        expect(component.any_red_zones?).to be false
      end
    end

    context "when there is no current quarter" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        Quarter.destroy_all
      end

      it "returns false" do
        component = described_class.new(teams: [team])
        expect(component.any_red_zones?).to be false
      end
    end
  end

  describe "#grouped_red_zones" do
    context "with single team" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns flat array" do
        component = described_class.new(teams: [team])
        expect(component.grouped_red_zones).to be_an(Array)
        expect(component.grouped_red_zones.size).to eq(1)
      end
    end

    context "with multiple teams" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "high")
        create(:team_technology, team: team2, technology: technology1, target_experts: 2, criticality: "normal")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user_in_team2, technology: technology1, quarter: current_quarter, rating: 2, team: team2)
      end

      it "returns hash grouped by technology" do
        component = described_class.new(teams: [team, team2])
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
        before do
          create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "high")
          create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        end

        it "renders red zones list" do
          component = described_class.new(teams: [team])
          render_inline(component)

          expect(page).to have_text("Red Zones")
          expect(page).to have_text(/critical coverage gaps/i)
          expect(page).to have_text(technology1.name)
          expect(page).to have_text("1/2")
        end
      end

      context "with multiple teams" do
        before do
          create(:team_technology, team: team, technology: technology3, target_experts: 2, criticality: "high")
          create(:team_technology, team: team2, technology: technology3, target_experts: 2, criticality: "normal")
          create(:skill_rating, user: user, technology: technology3, quarter: current_quarter, rating: 2, team: team)
          create(:skill_rating, user: user_in_team2, technology: technology3, quarter: current_quarter, rating: 2, team: team2)
        end

        it "renders grouped red zones with team links" do
          component = described_class.new(teams: [team, team2])
          render_inline(component)

          expect(page).to have_text("Red Zones")
          expect(page).to have_text(/critical coverage gaps/i)
          expect(page).to have_text(technology3.name, count: 1)
          expect(page).to have_text(team.name)
          expect(page).to have_text(team2.name)
          expect(page).to have_text("1/2", count: 2)
          expect(page).to have_link(team.name)
          expect(page).to have_link(team2.name)
        end
      end
    end

    context "when there are no red zones" do
      it "renders empty state message" do
        component = described_class.new(teams: [team])
        render_inline(component)

        expect(page).to have_text("Red Zones")
        expect(page).to have_text("No red zones detected")
      end
    end
  end

  describe "N+1 queries", :n_plus_one do
    before do
      n_plus_one_technologies.each do |tech|
        create(:team_technology, team: team, technology: tech,
          criticality: [:normal, :high].sample, target_experts: 2)
      end
    end

    populate do |n|
      ActiveRecord::Base.connection.clear_query_cache
      team.reload
      team.users.reset

      users = create_list(:user, n, team: team)

      users.each do |user|
        n_plus_one_technologies.each do |tech|
          create(:skill_rating,
            user: user,
            technology: tech,
            quarter: current_quarter,
            rating: rand(1..3),
            team: team)
        end
      end
    end

    specify do
      expect { render_inline(described_class.new(teams: [team])) }.to perform_constant_number_of_queries
    end
  end
end
