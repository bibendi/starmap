# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserRatingChangesQuery do
  let_it_be(:current_quarter) { create(:quarter, status: :active, is_current: true) }
  let_it_be(:previous_quarter) { create(:quarter, :previous, :closed, relative_to: current_quarter) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  describe "#changes_by_technology" do
    context "when rating improved" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns positive change" do
        result = described_class.new(user: user, quarter: current_quarter).changes_by_technology
        expect(result[technology1.id]).to eq(2)
      end
    end

    context "when rating decreased" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: previous_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 1, team: team)
      end

      it "returns negative change" do
        result = described_class.new(user: user, quarter: current_quarter).changes_by_technology
        expect(result[technology1.id]).to eq(-2)
      end
    end

    context "when rating did not change" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "excludes zero changes" do
        result = described_class.new(user: user, quarter: current_quarter).changes_by_technology
        expect(result).not_to have_key(technology1.id)
      end
    end

    context "when there is no previous quarter" do
      before do
        allow(current_quarter).to receive(:previous_quarter).and_return(nil)
      end

      it "returns empty hash" do
        result = described_class.new(user: user, quarter: current_quarter).changes_by_technology
        expect(result).to eq({})
      end
    end

    context "when quarter is nil" do
      it "returns empty hash" do
        result = described_class.new(user: user, quarter: nil).changes_by_technology
        expect(result).to eq({})
      end
    end

    context "with multiple technologies" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: previous_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 1, team: team)
      end

      it "returns changes for each technology" do
        result = described_class.new(user: user, quarter: current_quarter).changes_by_technology
        expect(result[technology1.id]).to eq(1)
        expect(result[technology2.id]).to eq(-2)
      end
    end
  end

  describe "N+1 queries", :n_plus_one do
    let_it_be(:technologies) { create_list(:technology, 3) }

    populate do |n|
      users = create_list(:user, n, team: team)

      users.each do |u|
        technologies.each do |tech|
          create(:skill_rating,
            user: u,
            technology: tech,
            quarter: previous_quarter,
            rating: rand(0..3),
            team: team)
          create(:skill_rating,
            user: u,
            technology: tech,
            quarter: current_quarter,
            rating: rand(0..3),
            team: team)
        end
      end
    end

    specify "#changes_by_technology performs constant number of queries" do
      u = team.users.first || create(:user, team: team)
      expect { described_class.new(user: u, quarter: current_quarter).changes_by_technology }.to perform_constant_number_of_queries
    end
  end
end
