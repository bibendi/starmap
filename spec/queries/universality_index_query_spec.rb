# frozen_string_literal: true

require "rails_helper"

RSpec.describe UniversalityIndexQuery do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  describe "#data" do
    context "when users have expert ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns count of technologies per user" do
        expect(described_class.new(team: team, quarter: current_quarter).data).to eq(user1.id => 2)
      end
    end

    context "when no expert ratings exist" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 1, team: team)
      end

      it "returns empty hash" do
        expect(described_class.new(team: team, quarter: current_quarter).data).to eq({})
      end
    end

    context "when there is no current quarter" do
      it "returns empty hash" do
        expect(described_class.new(team: team, quarter: nil).data).to eq({})
      end
    end
  end

  describe "N+1 queries", :n_plus_one do
    let_it_be(:technologies) { create_list(:technology, 3) }

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
      expect { described_class.new(team: team, quarter: current_quarter).data }.to perform_constant_number_of_queries
    end
  end
end
