# frozen_string_literal: true

class CompetencyDynamicsComponent < ViewComponent::Base
  attr_reader :competency_dynamics, :team_members

  def initialize(team:)
    @team = team
    @current_quarter = Quarter.current
    @team_members = @team&.users || []
    @competency_dynamics = calculate
  end

  private

  def calculate
    return {} unless @current_quarter

    previous_quarter = @current_quarter.previous_quarter
    return {} unless previous_quarter

    quarter_ids = [@current_quarter.id, previous_quarter.id]
    quarters = [@current_quarter, previous_quarter]
    skill_ratings_by_user = SkillRating
      .visible_for_quarters(quarters)
      .where(user_id: @team_members.map(&:id), quarter_id: quarter_ids, team_id: @team.id)
      .group_by(&:user_id)

    dynamics = {}
    @team_members.each do |user|
      user_ratings = skill_ratings_by_user[user.id] || []
      current_ratings = user_ratings.select { |r| r.quarter_id == @current_quarter.id }.index_by(&:technology_id)
      previous_ratings = user_ratings.select { |r| r.quarter_id == previous_quarter.id }.index_by(&:technology_id)

      total_change = current_ratings.sum do |tech_id, current_rating|
        previous_rating = previous_ratings[tech_id]&.rating || 0
        current_rating.rating - previous_rating
      end

      dynamics[user.id] = total_change
    end
    dynamics.reject { |_, change| change.zero? }
  end
end
