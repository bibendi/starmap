# frozen_string_literal: true

class UserRatingChangesQuery
  def initialize(user:, quarter:)
    @user = user
    @quarter = quarter
  end

  def changes_by_technology
    return {} unless @quarter

    previous_quarter = @quarter.previous_quarter
    return {} unless previous_quarter

    previous_ratings = SkillRating
      .visible_for_quarter(previous_quarter)
      .by_user(@user)
      .by_quarter(previous_quarter)
      .pluck(:technology_id, :rating)
      .to_h

    current_ratings = SkillRating
      .visible_for_quarter(@quarter)
      .by_user(@user)
      .by_quarter(@quarter)
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
