# frozen_string_literal: true

require "rails_helper"

RSpec.describe KeyPersonRisksQuery do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }
  let_it_be(:technology3) { create(:technology) }

  describe "#count" do
    context "when technologies have multiple experts" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns 0 key person risks" do
        expect(described_class.new(teams: [team], quarter: current_quarter).count).to eq(0)
      end
    end

    context "when technologies have single expert" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 1 key person risk" do
        expect(described_class.new(teams: [team], quarter: current_quarter).count).to eq(1)
      end
    end

    context "when multiple technologies have single expert" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology3, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 3 key person risks" do
        expect(described_class.new(teams: [team], quarter: current_quarter).count).to eq(3)
      end
    end

    context "when rating is below expert level" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 1, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 1, team: team)
      end

      it "does not count non-expert ratings" do
        expect(described_class.new(teams: [team], quarter: current_quarter).count).to eq(0)
      end
    end

    context "when there is no current quarter" do
      it "returns 0" do
        expect(described_class.new(teams: [team], quarter: nil).count).to eq(0)
      end
    end
  end

  describe "#details" do
    context "when technologies have single expert" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns risks with technology, team and user data" do
        result = described_class.new(teams: [team], quarter: current_quarter).details
        expect(result.size).to eq(2)
        tech_names = result.pluck(:technology).map(&:name)
        expect(tech_names).to include(technology1.name, technology2.name)
      end
    end

    context "when technologies have multiple experts" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns empty array" do
        expect(described_class.new(teams: [team], quarter: current_quarter).details).to be_empty
      end
    end

    context "when there is no current quarter" do
      it "returns empty array" do
        expect(described_class.new(teams: [team], quarter: nil).details).to be_empty
      end
    end
  end

  describe "N+1 queries", :n_plus_one do
    let_it_be(:technologies) { create_list(:technology, 3) }

    populate do |n|
      ActiveRecord::Base.connection.clear_query_cache

      users = create_list(:user, n, team: team)

      users.each_with_index do |user, index|
        technologies.each do |tech|
          rating = (index == 0) ? [2, 3].sample : 1
          create(:skill_rating,
            user: user,
            technology: tech,
            quarter: current_quarter,
            rating: rating,
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
