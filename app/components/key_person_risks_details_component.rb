# frozen_string_literal: true

class KeyPersonRisksDetailsComponent < ViewComponent::Base
  attr_reader :risks_data, :teams

  def initialize(teams:, risks_data:)
    @teams = teams
    @risks_data = risks_data
  end

  def any_risks?
    risks_data.any?
  end

  def multiple_teams?
    @teams.size > 1
  end

  def risks_count
    risks_data.size
  end

  def paginated_risks
    risks_data
  end

  def has_pagination?
    risks_count > 5
  end
end
