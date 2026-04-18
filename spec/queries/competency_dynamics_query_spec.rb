# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompetencyDynamicsQuery do
  let_it_be(:current_quarter) { create(:quarter, status: :active, is_current: true) }
  let_it_be(:previous_quarter) { create(:quarter, :previous, :closed, relative_to: current_quarter) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  describe "#data" do
    context "when users improved their skills" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: previous_quarter, rating: 0, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 1, team: team)
      end

      it "returns positive dynamics for user1" do
        result = described_class.new(team: team, user_ids: [user1.id, user2.id], quarter: current_quarter).data
        expect(result[user1.id]).to eq(3)
      end

      it "returns positive dynamics for user2" do
        result = described_class.new(team: team, user_ids: [user1.id, user2.id], quarter: current_quarter).data
        expect(result[user2.id]).to eq(1)
      end
    end

    context "when users skills decreased" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 0, team: team)
      end

      it "returns negative dynamics" do
        result = described_class.new(team: team, user_ids: [user1.id], quarter: current_quarter).data
        expect(result[user1.id]).to eq(-4)
      end
    end

    context "when skills did not change" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "excludes zero dynamics" do
        result = described_class.new(team: team, user_ids: [user1.id], quarter: current_quarter).data
        expect(result).not_to have_key(user1.id)
      end
    end

    context "when there is no current quarter" do
      it "returns empty hash" do
        result = described_class.new(team: team, user_ids: [user1.id], quarter: nil).data
        expect(result).to eq({})
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
            quarter: previous_quarter,
            rating: rand(0..3),
            team: team)
          create(:skill_rating,
            user: user,
            technology: tech,
            quarter: current_quarter,
            rating: rand(0..3),
            team: team)
        end
      end
    end

    specify "#data performs constant number of queries" do
      user_ids = team.user_ids
      expect { described_class.new(team: team, user_ids: user_ids, quarter: current_quarter).data }.to perform_constant_number_of_queries
    end
  end
end
