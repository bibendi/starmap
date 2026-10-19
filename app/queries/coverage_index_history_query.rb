# frozen_string_literal: true

class CoverageIndexHistoryQuery
  MAX_PERIODS = 10

  def initialize(teams:)
    @teams = teams
  end

  def data
    assessment_periods.map do |assessment_period|
      {
        period_name: assessment_period.full_name,
        coverage_index: CoverageIndexQuery.new(teams: @teams, assessment_period: assessment_period).percentage
      }
    end
  end

  private

  def assessment_periods
    AssessmentPeriod.where.not(status: :draft).ordered.last(MAX_PERIODS)
  end
end
