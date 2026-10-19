# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoverageIndexHistoryQuery do
  let_it_be(:team) { create(:team) }
  let_it_be(:technology) { create(:technology) }

  before do
    create(:team_technology, team: team, technology: technology, target_experts: 1)
  end

  describe "#data" do
    context "with multiple assessment_periods" do
      let_it_be(:q1) { create(:assessment_period, year: 2025, quarter_number: 1, status: :closed) }
      let_it_be(:q2) { create(:assessment_period, year: 2025, quarter_number: 2, status: :closed) }
      let_it_be(:q3) { create(:assessment_period, year: 2025, quarter_number: 3, status: :active) }

      before do
        create(:skill_rating, user: create(:user, team: team), technology: technology, assessment_period: q1, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology, assessment_period: q2, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology, assessment_period: q3, rating: 2, team: team)
      end

      it "returns array of hashes with period_name and coverage_index" do
        result = described_class.new(teams: [team]).data

        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result.first).to include(:period_name, :coverage_index)
        expect(result.first[:period_name]).to eq("2025 Q1")
        expect(result.last[:period_name]).to eq("2025 Q3")
      end

      it "returns assessment_periods in chronological order" do
        result = described_class.new(teams: [team]).data
        names = result.pluck(:period_name)

        expect(names).to eq(["2025 Q1", "2025 Q2", "2025 Q3"])
      end
    end

    context "with no non-draft assessment_periods" do
      before { create(:assessment_period, status: :draft) }

      it "returns empty array" do
        result = described_class.new(teams: [team]).data
        expect(result).to eq([])
      end
    end

    context "excluding draft assessment_periods" do
      let_it_be(:closed_q) { create(:assessment_period, year: 2025, quarter_number: 1, status: :closed) }

      before do
        create(:assessment_period, year: 2025, quarter_number: 2, status: :draft)
        create(:skill_rating, user: create(:user, team: team), technology: technology, assessment_period: closed_q, rating: 2, team: team)
      end

      it "only includes non-draft assessment_periods" do
        result = described_class.new(teams: [team]).data
        expect(result.size).to eq(1)
        expect(result.first[:period_name]).to eq("2025 Q1")
      end
    end

    context "with more than MAX_PERIODS assessment_periods" do
      before do
        12.times do |i|
          q = create(:assessment_period, year: 2024 + (i / 4), quarter_number: (i % 4) + 1, status: :closed)
          create(:skill_rating, user: create(:user, team: team), technology: technology, assessment_period: q, rating: 2, team: team)
        end
      end

      it "returns at most MAX_PERIODS results" do
        result = described_class.new(teams: [team]).data
        expect(result.size).to eq(described_class::MAX_PERIODS)
      end

      it "returns the most recent assessment_periods" do
        all_assessment_periods = AssessmentPeriod.where.not(status: :draft).ordered
        expected_last = all_assessment_periods.last(described_class::MAX_PERIODS).map(&:full_name)
        result = described_class.new(teams: [team]).data
        expect(result.pluck(:period_name)).to eq(expected_last)
      end
    end
  end
end
