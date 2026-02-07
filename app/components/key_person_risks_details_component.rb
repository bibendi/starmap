# frozen_string_literal: true

class KeyPersonRisksDetailsComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :risks_data, :teams

  def initialize(teams:)
    @teams = teams
    @risks_data = calculate
  end

  def any_risks?
    risks_data.any?
  end

  def multiple_teams?
    @teams.size > 1
  end

  private

  def calculate
    current_quarter = Quarter.current
    return [] unless current_quarter

    tech_ids_with_single_expert = SkillRating
      .where(quarter: current_quarter, team_id: @teams.map(&:id), rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING)
      .group(:technology_id)
      .having("COUNT(DISTINCT user_id) = 1")
      .pluck(:technology_id)

    return [] if tech_ids_with_single_expert.empty?

    SkillRating
      .preload(:technology, :user, :team)
      .where(quarter: current_quarter, team_id: @teams.map(&:id), rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, technology_id: tech_ids_with_single_expert)
      .map do |rating|
        {
          technology: rating.technology,
          team: rating.team,
          user: rating.user
        }
      end
      .sort_by { |risk| risk[:technology]&.name || "" }
  end
end
