# frozen_string_literal: true

class RedZonesDetailsComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :red_zones_data

  def initialize(team:)
    @team = team
    @red_zones_data = calculate
  end

  def any_red_zones?
    red_zones_data.any?
  end

  private

  def calculate
    current_quarter = Quarter.current
    return [] unless current_quarter

    team_technologies = @team.team_technologies.includes(:technology)
      .where(criticality: [:normal, 'high'])

    red_zones = team_technologies.each_with_object([]) do |team_tech, result|
      expert_count = expert_count_for(team_tech.technology, current_quarter)
      if expert_count < team_tech.target_experts
        result << {
          technology: team_tech.technology,
          expert_count: expert_count
        }
      end
    end

    red_zones
  end

  def expert_count_for(technology, quarter)
    technology.skill_ratings
      .where(quarter: quarter, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, team_id: @team.id)
      .count
  end
end
