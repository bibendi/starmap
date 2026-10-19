# frozen_string_literal: true

class UniversalityIndexQuery
  def initialize(team:, assessment_period: AssessmentPeriod.current)
    @team = team
    @assessment_period = assessment_period
  end

  def data
    return {} unless @assessment_period

    SkillRating
      .visible_for_assessment_period(@assessment_period)
      .expert_ratings
      .where(assessment_period: @assessment_period, team_id: @team.id)
      .group(:user_id)
      .count
  end
end
