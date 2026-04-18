# frozen_string_literal: true

class MaturityIndexQuery
  def initialize(teams:, quarter: Quarter.current)
    @teams = teams
    @quarter = quarter
  end

  def value
    return 0 unless @quarter

    ratings = SkillRating.visible_for_quarter(@quarter).where(team_id: team_ids, quarter: @quarter)
    ratings.average(:rating)&.round(1) || 0
  end

  private

  def team_ids
    @teams.map(&:id)
  end
end
