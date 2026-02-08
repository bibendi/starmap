# frozen_string_literal: true

class RedZonesDetailsComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :red_zones_data, :teams

  def initialize(teams:)
    @teams = teams
    @red_zones_data = calculate
  end

  def any_red_zones?
    red_zones_data.any?
  end

  def multiple_teams?
    @teams.size > 1
  end

  private

  def calculate
    current_quarter = Quarter.current
    return [] unless current_quarter

    team_technologies = TeamTechnology
      .includes(:technology, :team)
      .where(team_id: @teams.map(&:id), criticality: [:normal, :high])

    technology_ids = team_technologies.map(&:technology_id)
    team_ids = @teams.map(&:id)

    expert_counts = SkillRating
      .where(
        quarter: current_quarter,
        technology_id: technology_ids,
        rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING,
        team_id: team_ids
      )
      .group(:technology_id, :team_id)
      .count

    red_zones = team_technologies.each_with_object([]) do |team_tech, result|
      expert_count = expert_counts[[team_tech.technology_id, team_tech.team_id]] || 0
      if expert_count < team_tech.target_experts
        result << {
          technology: team_tech.technology,
          team: team_tech.team,
          expert_count: expert_count,
          target_experts: team_tech.target_experts,
          deficit: team_tech.target_experts - expert_count
        }
      end
    end

    red_zones.sort_by { |red_zone| red_zone[:technology]&.name || "" }
  end
end
