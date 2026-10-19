# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserRatingChangesQuery do
  let_it_be(:current_assessment_period) { create(:assessment_period, status: :active, is_current: true) }
  let_it_be(:previous_assessment_period) { create(:assessment_period, :previous, :closed, relative_to: current_assessment_period) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  describe "#changes_by_technology" do
    context "when rating improved" do
      before do
        create(:skill_rating, user: user, technology: technology1, assessment_period: previous_assessment_period, rating: 1, team: team)
        create(:skill_rating, user: user, technology: technology1, assessment_period: current_assessment_period, rating: 3, team: team)
      end

      it "returns positive change" do
        result = described_class.new(user: user, assessment_period: current_assessment_period).changes_by_technology
        expect(result[technology1.id]).to eq(2)
      end
    end

    context "when rating decreased" do
      before do
        create(:skill_rating, user: user, technology: technology1, assessment_period: previous_assessment_period, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology1, assessment_period: current_assessment_period, rating: 1, team: team)
      end

      it "returns negative change" do
        result = described_class.new(user: user, assessment_period: current_assessment_period).changes_by_technology
        expect(result[technology1.id]).to eq(-2)
      end
    end

    context "when rating did not change" do
      before do
        create(:skill_rating, user: user, technology: technology1, assessment_period: previous_assessment_period, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology1, assessment_period: current_assessment_period, rating: 2, team: team)
      end

      it "excludes zero changes" do
        result = described_class.new(user: user, assessment_period: current_assessment_period).changes_by_technology
        expect(result).not_to have_key(technology1.id)
      end
    end

    context "when there is no previous assessment_period" do
      before do
        allow(current_assessment_period).to receive(:previous_assessment_period).and_return(nil)
      end

      it "returns empty hash" do
        result = described_class.new(user: user, assessment_period: current_assessment_period).changes_by_technology
        expect(result).to eq({})
      end
    end

    context "when assessment_period is nil" do
      it "returns empty hash" do
        result = described_class.new(user: user, assessment_period: nil).changes_by_technology
        expect(result).to eq({})
      end
    end

    context "with multiple technologies" do
      before do
        create(:skill_rating, user: user, technology: technology1, assessment_period: previous_assessment_period, rating: 1, team: team)
        create(:skill_rating, user: user, technology: technology1, assessment_period: current_assessment_period, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology2, assessment_period: previous_assessment_period, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, assessment_period: current_assessment_period, rating: 1, team: team)
      end

      it "returns changes for each technology" do
        result = described_class.new(user: user, assessment_period: current_assessment_period).changes_by_technology
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
            assessment_period: previous_assessment_period,
            rating: rand(0..3),
            team: team)
          create(:skill_rating,
            user: u,
            technology: tech,
            assessment_period: current_assessment_period,
            rating: rand(0..3),
            team: team)
        end
      end
    end

    specify "#changes_by_technology performs constant number of queries" do
      u = team.users.first || create(:user, team: team)
      expect { described_class.new(user: u, assessment_period: current_assessment_period).changes_by_technology }.to perform_constant_number_of_queries
    end
  end
end
