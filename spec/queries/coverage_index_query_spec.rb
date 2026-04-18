# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoverageIndexQuery do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  before do
    create(:team_technology, team: team, technology: technology1, target_experts: 2)
    create(:team_technology, team: team, technology: technology2, target_experts: 2)
  end

  describe "#percentage" do
    context "when technologies have sufficient experts" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns 100% coverage" do
        expect(described_class.new(teams: [team], quarter: current_quarter).percentage).to eq(100)
      end
    end

    context "when technologies have insufficient experts" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 50% coverage" do
        expect(described_class.new(teams: [team], quarter: current_quarter).percentage).to eq(50)
      end
    end

    context "when team has no technologies" do
      let(:empty_team) { create(:team) }

      it "returns 0" do
        expect(described_class.new(teams: [empty_team], quarter: current_quarter).percentage).to eq(0)
      end
    end

    context "when there is no current quarter" do
      it "returns 0" do
        expect(described_class.new(teams: [team], quarter: nil).percentage).to eq(0)
      end
    end

    context "when custom target_experts is set" do
      before do
        team.team_technologies.find_by(technology: technology1).update(target_experts: 1)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "calculates based on custom target" do
        expect(described_class.new(teams: [team], quarter: current_quarter).percentage).to eq(50)
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

    specify "#percentage performs constant number of queries" do
      expect { described_class.new(teams: [team], quarter: current_quarter).percentage }.to perform_constant_number_of_queries
    end
  end
end
