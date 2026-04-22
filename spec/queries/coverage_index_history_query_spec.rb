# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoverageIndexHistoryQuery do
  let_it_be(:team) { create(:team) }
  let_it_be(:technology) { create(:technology) }

  before do
    create(:team_technology, team: team, technology: technology, target_experts: 1)
  end

  describe "#data" do
    context "with multiple quarters" do
      let_it_be(:q1) { create(:quarter, year: 2025, quarter_number: 1, status: :closed) }
      let_it_be(:q2) { create(:quarter, year: 2025, quarter_number: 2, status: :closed) }
      let_it_be(:q3) { create(:quarter, year: 2025, quarter_number: 3, status: :active) }

      before do
        create(:skill_rating, user: create(:user, team: team), technology: technology, quarter: q1, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology, quarter: q2, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology, quarter: q3, rating: 2, team: team)
      end

      it "returns array of hashes with quarter_name and coverage_index" do
        result = described_class.new(teams: [team]).data

        expect(result).to be_an(Array)
        expect(result.size).to eq(3)
        expect(result.first).to include(:quarter_name, :coverage_index)
        expect(result.first[:quarter_name]).to eq("2025 Q1")
        expect(result.last[:quarter_name]).to eq("2025 Q3")
      end

      it "returns quarters in chronological order" do
        result = described_class.new(teams: [team]).data
        names = result.pluck(:quarter_name)

        expect(names).to eq(["2025 Q1", "2025 Q2", "2025 Q3"])
      end
    end

    context "with no non-draft quarters" do
      before { create(:quarter, status: :draft) }

      it "returns empty array" do
        result = described_class.new(teams: [team]).data
        expect(result).to eq([])
      end
    end

    context "excluding draft quarters" do
      let_it_be(:closed_q) { create(:quarter, year: 2025, quarter_number: 1, status: :closed) }

      before do
        create(:quarter, year: 2025, quarter_number: 2, status: :draft)
        create(:skill_rating, user: create(:user, team: team), technology: technology, quarter: closed_q, rating: 2, team: team)
      end

      it "only includes non-draft quarters" do
        result = described_class.new(teams: [team]).data
        expect(result.size).to eq(1)
        expect(result.first[:quarter_name]).to eq("2025 Q1")
      end
    end

    context "with more than MAX_QUARTERS quarters" do
      before do
        12.times do |i|
          q = create(:quarter, year: 2024 + (i / 4), quarter_number: (i % 4) + 1, status: :closed)
          create(:skill_rating, user: create(:user, team: team), technology: technology, quarter: q, rating: 2, team: team)
        end
      end

      it "returns at most MAX_QUARTERS results" do
        result = described_class.new(teams: [team]).data
        expect(result.size).to eq(described_class::MAX_QUARTERS)
      end

      it "returns the most recent quarters" do
        all_quarters = Quarter.where.not(status: :draft).ordered
        expected_last = all_quarters.last(described_class::MAX_QUARTERS).map(&:full_name)
        result = described_class.new(teams: [team]).data
        expect(result.pluck(:quarter_name)).to eq(expected_last)
      end
    end
  end
end
