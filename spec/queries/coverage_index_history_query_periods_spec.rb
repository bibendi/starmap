require "rails_helper"

RSpec.describe CoverageIndexHistoryQuery do
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology) { create(:technology) }
  let_it_be(:team_technology) { create(:team_technology, team: team, technology: technology, target_experts: 1) }
  let_it_be(:quarterly) { create(:assessment_period, :closed, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 3, 31)) }
  let_it_be(:monthly) { create(:assessment_period, :closed, period_kind: :monthly, start_date: Date.new(2026, 4, 1), end_date: Date.new(2026, 4, 30)) }
  let_it_be(:custom) { create(:assessment_period, :draft, period_kind: :custom, start_date: Date.new(2026, 5, 15), end_date: Date.new(2026, 6, 20)) }

  before do
    [quarterly, monthly].each do |period|
      create(:skill_rating, user: user, team: team, technology: technology, assessment_period: period, rating: 3, status: :approved)
    end
  end

  it "uses the same formulas for mixed types and excludes draft snapshots" do
    coverage = described_class.new(teams: [team]).data
    maturity = MaturityIndexHistoryQuery.new(teams: [team]).data
    expect(coverage).to eq([{period_name: "2026 Q1", coverage_index: 100}, {period_name: "2026-04", coverage_index: 100}])
    expect(maturity).to eq([{period_name: "2026 Q1", maturity_index: 3.0}, {period_name: "2026-04", maturity_index: 3.0}])
    expect(custom.previous_assessment_period).to eq(monthly)
    expect(UserRatingChangesQuery.new(user: user, assessment_period: monthly).changes_by_technology).to eq({})
  end

  it "limits both histories to ten latest nondraft periods" do
    12.times do |index|
      start_date = Date.new(2030, index + 1, 1)
      create(:assessment_period, :closed, period_kind: :monthly, start_date: start_date, end_date: start_date.end_of_month)
    end
    expected_names = (3..12).map { |month| format("2030-%02d", month) }
    [described_class, MaturityIndexHistoryQuery].each do |query_class|
      expect(query_class.new(teams: [team]).data.pluck(:period_name)).to eq(expected_names)
    end
  end

  describe "N+1 queries", :n_plus_one do
    populate do |n|
      users = create_list(:user, n, team: team)
      users.each do |member|
        [quarterly, monthly].each do |period|
          create(:skill_rating, user: member, team: team, technology: technology, assessment_period: period, rating: 2, status: :approved)
        end
      end
    end

    it "keeps coverage history queries constant as ratings scale" do
      expect { described_class.new(teams: [team]).data }.to perform_constant_number_of_queries
    end

    it "keeps maturity history queries constant as ratings scale" do
      expect { MaturityIndexHistoryQuery.new(teams: [team]).data }.to perform_constant_number_of_queries
    end
  end
end
