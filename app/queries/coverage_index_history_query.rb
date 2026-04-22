# frozen_string_literal: true

class CoverageIndexHistoryQuery
  MAX_QUARTERS = 10

  def initialize(teams:)
    @teams = teams
  end

  def data
    quarters.map do |quarter|
      {
        quarter_name: quarter.full_name,
        coverage_index: CoverageIndexQuery.new(teams: @teams, quarter: quarter).percentage
      }
    end
  end

  private

  def quarters
    Quarter.where.not(status: :draft).ordered.last(MAX_QUARTERS)
  end
end
