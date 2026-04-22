# frozen_string_literal: true

class MaturityIndexHistoryQuery
  MAX_QUARTERS = 10

  def initialize(teams:)
    @teams = teams
  end

  def data
    quarters.map do |quarter|
      {
        quarter_name: quarter.full_name,
        maturity_index: MaturityIndexQuery.new(teams: @teams, quarter: quarter).value.to_f
      }
    end
  end

  private

  def quarters
    Quarter.where.not(status: :draft).ordered.last(MAX_QUARTERS)
  end
end
