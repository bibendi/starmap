# frozen_string_literal: true

class MaturityIndexQuery
  def initialize(teams:, assessment_period: AssessmentPeriod.current)
    @teams = teams
    @assessment_period = assessment_period
  end

  def value
    return 0 unless @assessment_period

    ratings = SkillRating.visible_for_assessment_period(@assessment_period).where(team_id: team_ids, assessment_period: @assessment_period)
    ratings.average(:rating)&.round(1) || 0
  end

  private

  def team_ids
    @teams.map(&:id)
  end
end
