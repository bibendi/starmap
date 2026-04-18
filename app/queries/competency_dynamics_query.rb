# frozen_string_literal: true

class CompetencyDynamicsQuery
  def initialize(team:, user_ids:, quarter: Quarter.current)
    @team = team
    @user_ids = user_ids
    @quarter = quarter
  end

  def data
    return {} unless @quarter

    previous_quarter = @quarter.previous_quarter
    return {} unless previous_quarter

    quarter_ids = [@quarter.id, previous_quarter.id]
    quarters = [@quarter, previous_quarter]

    skill_ratings_by_user = SkillRating
      .visible_for_quarters(quarters)
      .where(user_id: @user_ids, quarter_id: quarter_ids, team_id: @team.id)
      .group_by(&:user_id)

    dynamics = {}
    @user_ids.each do |user_id|
      user_ratings = skill_ratings_by_user[user_id] || []
      current_ratings = user_ratings.select { |r| r.quarter_id == @quarter.id }.index_by(&:technology_id)
      previous_ratings = user_ratings.select { |r| r.quarter_id == previous_quarter.id }.index_by(&:technology_id)

      total_change = current_ratings.sum do |tech_id, current_rating|
        previous_rating = previous_ratings[tech_id]&.rating || 0
        current_rating.rating - previous_rating
      end

      dynamics[user_id] = total_change
    end
    dynamics.reject { |_, change| change.zero? }
  end
end
