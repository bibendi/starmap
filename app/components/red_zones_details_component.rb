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
      .where(criticality: [:normal, :high])

    technology_ids = team_technologies.map(&:technology_id)

    expert_counts = SkillRating.where(
      quarter: current_quarter,
      technology_id: technology_ids,
      rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING,
      team_id: @team.id
    ).group(:technology_id).count

    team_technologies.each_with_object([]) do |team_tech, result|
      expert_count = expert_counts[team_tech.technology_id] || 0
      if expert_count < team_tech.target_experts
        result << {
          technology: team_tech.technology,
          expert_count: expert_count
        }
      end
    end
  end
end
