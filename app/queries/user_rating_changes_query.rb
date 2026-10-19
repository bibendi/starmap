# frozen_string_literal: true

class UserRatingChangesQuery
  def initialize(user:, assessment_period:)
    @user = user
    @assessment_period = assessment_period
  end

  def changes_by_technology
    return {} unless @assessment_period

    previous_assessment_period = @assessment_period.previous_assessment_period
    return {} unless previous_assessment_period

    previous_ratings = SkillRating
      .visible_for_assessment_period(previous_assessment_period)
      .by_user(@user)
      .by_assessment_period(previous_assessment_period)
      .pluck(:technology_id, :rating)
      .to_h

    current_ratings = SkillRating
      .visible_for_assessment_period(@assessment_period)
      .by_user(@user)
      .by_assessment_period(@assessment_period)
      .pluck(:technology_id, :rating)
      .to_h

    all_tech_ids = (previous_ratings.keys + current_ratings.keys).uniq

    all_tech_ids.each_with_object({}) do |tech_id, changes|
      current = current_ratings[tech_id] || 0
      previous = previous_ratings[tech_id] || 0
      change = current - previous
      next if change.zero?

      changes[tech_id] = change
    end
  end
end
