# frozen_string_literal: true

class UniversalityIndexComponent < ViewComponent::Base
  include ExpertConstants

  def initialize(team:)
    @team = team
    @universality_index = calculate
  end

  private

  def calculate
    current_quarter = Quarter.current
    return {} unless current_quarter

    SkillRating
      .where(quarter: current_quarter, team_id: @team.id, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, status: :approved)
      .group(:user_id)
      .count
  end
end
