# frozen_string_literal: true

require "rails_helper"

RSpec.describe UnitTechnologyTreemapQuery do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }
  let_it_be(:technology3) { create(:technology) }

  describe "#data" do
    context "when there are technologies with experts" do
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

      it "returns technologies sorted by expert count descending" do
        result = described_class.new(teams: [team], quarter: current_quarter).data
        expect(result.size).to eq(3)
        expect(result[0][:expert_count]).to eq(3)
        expect(result[1][:expert_count]).to eq(2)
        expect(result[2][:expert_count]).to eq(1)
      end

      it "marks technologies as all_teams_in_target when target is met" do
        result = described_class.new(teams: [team], quarter: current_quarter).data
        expect(result[0][:all_teams_in_target]).to be true
        expect(result[1][:all_teams_in_target]).to be true
        expect(result[2][:all_teams_in_target]).to be false
      end

      it "calculates deficit for technologies below target" do
        result = described_class.new(teams: [team], quarter: current_quarter).data
        expect(result[0][:deficit]).to eq(0)
        expect(result[1][:deficit]).to eq(0)
        expect(result[2][:deficit]).to eq(1)
      end
    end

    context "when technology has no experts" do
      before do
        create(:team_technology, team: team, technology: technology1, target_experts: 2)
      end

      it "excludes technologies with zero experts" do
        expect(described_class.new(teams: [team], quarter: current_quarter).data).to be_empty
      end
    end

    context "when there is no current quarter" do
      it "returns empty array" do
        expect(described_class.new(teams: [team], quarter: nil).data).to be_empty
      end
    end
  end

  describe "N+1 queries", :n_plus_one do
    let_it_be(:technologies) { create_list(:technology, 3) }

    before do
      technologies.each do |tech|
        create(:team_technology, team: team, technology: tech, target_experts: 2)
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

    specify "#data performs constant number of queries" do
      expect { described_class.new(teams: [team], quarter: current_quarter).data }.to perform_constant_number_of_queries
    end
  end
end
