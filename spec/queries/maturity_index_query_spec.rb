# frozen_string_literal: true

require "rails_helper"

RSpec.describe MaturityIndexQuery do
  let_it_be(:current_assessment_period) { create(:assessment_period, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  describe "#value" do
    context "when ratings exist" do
      before do
        create(:skill_rating, user: user, technology: technology1, assessment_period: current_assessment_period, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology2, assessment_period: current_assessment_period, rating: 3, team: team)
      end

      it "calculates average rating" do
        expect(described_class.new(teams: [team], assessment_period: current_assessment_period).value).to eq(2.5)
      end
    end

    context "when no ratings exist" do
      it "returns 0" do
        expect(described_class.new(teams: [team], assessment_period: current_assessment_period).value).to eq(0)
      end
    end

    context "when there is no current assessment_period" do
      it "returns 0" do
        expect(described_class.new(teams: [team], assessment_period: nil).value).to eq(0)
      end
    end

    context "when ratings include zero values" do
      before do
        create(:skill_rating, user: user, technology: technology1, assessment_period: current_assessment_period, rating: 0, team: team)
        create(:skill_rating, user: user, technology: technology2, assessment_period: current_assessment_period, rating: 3, team: team)
      end

      it "includes zero values in average" do
        expect(described_class.new(teams: [team], assessment_period: current_assessment_period).value).to eq(1.5)
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
            assessment_period: current_assessment_period,
            rating: rand(1..3),
            team: team)
        end
      end
    end

    specify "#value performs constant number of queries" do
      expect { described_class.new(teams: [team], assessment_period: current_assessment_period).value }.to perform_constant_number_of_queries
    end
  end
end
