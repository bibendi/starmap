# frozen_string_literal: true

class MaturityIndexHistoryQuery
  MAX_PERIODS = 10

  def initialize(teams:)
    @teams = teams
  end

  def data
    assessment_periods.map do |assessment_period|
      {
        period_name: assessment_period.full_name,
        maturity_index: MaturityIndexQuery.new(teams: @teams, assessment_period: assessment_period).value.to_f
      }
    end
  end

  private

  def assessment_periods
    AssessmentPeriod.where.not(status: :draft).ordered.last(MAX_PERIODS)
  end
end
