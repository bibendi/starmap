# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedZonesDetailsComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  describe "#red_zones_data" do
    context "when technologies have sufficient experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns empty array" do
        component = described_class.new(teams: [team])
        expect(component.red_zones_data).to be_empty
      end
    end

    context "when technologies have insufficient experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns red zone with expert count" do
        component = described_class.new(teams: [team])
        red_zone = component.red_zones_data.first

        expect(red_zone[:technology]).to eq(technology1)
        expect(red_zone[:expert_count]).to eq(1)
      end
    end

    context "when team has no technologies" do
      let(:empty_team) { create(:team) }

      it "returns empty array" do
        component = described_class.new(teams: [empty_team])
        expect(component.red_zones_data).to be_empty
      end
    end

    context "when technology has low criticality" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "low")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "does not include low criticality technologies" do
        component = described_class.new(teams: [team])
        expect(component.red_zones_data).to be_empty
      end
    end

    context "when there is no current quarter" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        Quarter.destroy_all
      end

      it "returns empty array" do
        component = described_class.new(teams: [team])
        expect(component.red_zones_data).to be_empty
      end
    end
  end

  describe "#any_red_zones?" do
    context "when there are red zones" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns true" do
        component = described_class.new(teams: [team])
        expect(component.any_red_zones?).to be true
      end
    end

    context "when there are no red zones" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
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

  describe "rendering" do
    context "when there are red zones" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "renders red zones list" do
        component = described_class.new(teams: [team])
        render_inline(component)

        expect(page).to have_text("Red Zones")
        expect(page).to have_text("Critical technologies with insufficient coverage")
        expect(page).to have_text(technology1.name)
        expect(page).to have_text("1/2")
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
    let_it_be(:technologies) { create_list(:technology, 3) }

    before do
      technologies.each do |tech|
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
        technologies.each do |tech|
          create(:skill_rating,
            user: user,
            technology: tech,
            quarter: current_quarter,
            rating: rand(0..3),
            team: team)
        end
      end
    end

    specify do
      expect { render_inline(described_class.new(teams: [team])) }.to perform_constant_number_of_queries
    end
  end
end
