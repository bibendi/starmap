# frozen_string_literal: true

class UniversalityIndexQuery
  def initialize(team:, quarter: Quarter.current)
    @team = team
    @quarter = quarter
  end

  def data
    return {} unless @quarter

    SkillRating
      .visible_for_quarter(@quarter)
      .expert_ratings
      .where(quarter: @quarter, team_id: @team.id)
      .group(:user_id)
      .count
  end
end
