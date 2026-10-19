# frozen_string_literal: true

class KeyPersonRisksQuery
  def initialize(teams:, assessment_period: AssessmentPeriod.current)
    @teams = teams
    @assessment_period = assessment_period
  end

  def count
    return 0 unless @assessment_period

    SkillRating
      .visible_for_assessment_period(@assessment_period)
      .expert_ratings
      .where(assessment_period: @assessment_period, team_id: team_ids)
      .group(:technology_id)
      .having("COUNT(DISTINCT user_id) = 1")
      .count
      .size
  end

  def details
    return [] unless @assessment_period

    tech_ids_with_single_expert = SkillRating
      .visible_for_assessment_period(@assessment_period)
      .expert_ratings
      .where(assessment_period: @assessment_period, team_id: team_ids)
      .group(:technology_id)
      .having("COUNT(DISTINCT user_id) = 1")
      .pluck(:technology_id)

    return [] if tech_ids_with_single_expert.empty?

    SkillRating
      .preload(:technology, :user, :team)
      .visible_for_assessment_period(@assessment_period)
      .expert_ratings
      .where(assessment_period: @assessment_period, team_id: team_ids, technology_id: tech_ids_with_single_expert)
      .map do |rating|
        {
          technology: rating.technology,
          team: rating.team,
          user: rating.user
        }
      end
      .sort_by { |risk| risk[:technology]&.name || "" }
  end

  private

  def team_ids
    @teams.map(&:id)
  end
end
