# frozen_string_literal: true

class CompetencyDynamicsQuery
  def initialize(team:, user_ids:, assessment_period: AssessmentPeriod.current)
    @team = team
    @user_ids = user_ids
    @assessment_period = assessment_period
  end

  def data
    return {} unless @assessment_period

    previous_assessment_period = @assessment_period.previous_assessment_period
    return {} unless previous_assessment_period

    assessment_period_ids = [@assessment_period.id, previous_assessment_period.id]
    assessment_periods = [@assessment_period, previous_assessment_period]

    skill_ratings_by_user = SkillRating
      .visible_for_assessment_periods(assessment_periods)
      .where(user_id: @user_ids, assessment_period_id: assessment_period_ids, team_id: @team.id)
      .group_by(&:user_id)

    dynamics = {}
    @user_ids.each do |user_id|
      user_ratings = skill_ratings_by_user[user_id] || []
      current_ratings = user_ratings.select { |r| r.assessment_period_id == @assessment_period.id }.index_by(&:technology_id)
      previous_ratings = user_ratings.select { |r| r.assessment_period_id == previous_assessment_period.id }.index_by(&:technology_id)

      total_change = current_ratings.sum do |tech_id, current_rating|
        previous_rating = previous_ratings[tech_id]&.rating || 0
        current_rating.rating - previous_rating
      end

      dynamics[user_id] = total_change
    end
    dynamics.reject { |_, change| change.zero? }
  end
end
