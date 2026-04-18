# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedZonesQuery do
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

  describe "#count" do
    context "when technologies have sufficient experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns 0 red zones" do
        expect(described_class.new(teams: [team]).count).to eq(0)
      end
    end

    context "when technologies have insufficient experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 1, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 1 red zone" do
        expect(described_class.new(teams: [team]).count).to eq(1)
      end
    end

    context "when team has no technologies" do
      let(:empty_team) { create(:team) }

      it "returns 0 red zones" do
        expect(described_class.new(teams: [empty_team]).count).to eq(0)
      end
    end

    context "when technology has low criticality" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "low")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "does not count low criticality technologies" do
        expect(described_class.new(teams: [team]).count).to eq(0)
      end
    end

    context "when there is no current quarter" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        Quarter.destroy_all
      end

      it "returns 0 red zones" do
        expect(described_class.new(teams: [team]).count).to eq(0)
      end
    end

    context "with custom target_experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 1)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: "high")
      end

      it "calculates based on custom target" do
        expect(described_class.new(teams: [team]).count).to eq(1)
      end
    end

    context "when multiple teams are provided" do
      let_it_be(:user_in_team2_for_multi) { create(:user, team: team2) }

      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "high")
        create(:team_technology, team: team2, technology: technology1, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user_in_team2_for_multi, technology: technology1, quarter: current_quarter, rating: 1, team: team2)
      end

      it "counts red zones per team-technology combination" do
        expect(described_class.new(teams: [team, team2]).count).to eq(1)
      end
    end
  end

  describe "#details" do
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
        expect(described_class.new(teams: [team]).details).to be_empty
      end
    end

    context "when there are no red zones" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns empty array" do
        expect(described_class.new(teams: [team]).details).to be_empty
      end
    end

    context "when there is no current quarter" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
        Quarter.destroy_all
      end

      it "returns empty array" do
        expect(described_class.new(teams: [team]).details).to be_empty
      end
    end

    context "when there are red zones" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "high")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 1, team: team)
      end

      it "returns red zones with correct attributes" do
        result = described_class.new(teams: [team]).details

        expect(result.size).to eq(1)
        expect(result.first[:technology]).to eq(technology1)
        expect(result.first[:team]).to eq(team)
        expect(result.first[:expert_count]).to eq(0)
        expect(result.first[:target_experts]).to eq(2)
        expect(result.first[:deficit]).to eq(2)
        expect(result.first[:experts]).to be_empty
      end
    end

    context "with multiple teams" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: "high")
        create(:team_technology, team: team2, technology: technology1, target_experts: 2, criticality: "normal")
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 1, team: team)
        create(:skill_rating, user: user_in_team2, technology: technology1, quarter: current_quarter, rating: 1, team: team2)
      end

      it "returns red zones for each team" do
        result = described_class.new(teams: [team, team2]).details

        expect(result.size).to eq(2)
        expect(result.pluck(:team)).to contain_exactly(team, team2)
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

      users = create_list(:user, n, team: team)

      users.each do |user|
        technologies.each do |tech|
          create(:skill_rating,
            user: user,
            technology: tech,
            quarter: current_quarter,
            rating: rand(1..3),
            team: team)
        end
      end
    end

    specify "#count performs constant number of queries" do
      expect { described_class.new(teams: [team], quarter: current_quarter).count }.to perform_constant_number_of_queries
    end

    specify "#details performs constant number of queries" do
      expect { described_class.new(teams: [team], quarter: current_quarter).details }.to perform_constant_number_of_queries
    end
  end
end
