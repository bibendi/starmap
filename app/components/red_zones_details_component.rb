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

  def grouped_red_zones
    return red_zones_data unless multiple_teams?

    red_zones_data.group_by { |red_zone| red_zone[:technology] }
  end

  def red_zones_technologies_count
    if multiple_teams?
      grouped_red_zones.size
    else
      red_zones_data.pluck(:technology).uniq.size
    end
  end

  def carousel_slides
    if multiple_teams?
      grouped_red_zones.map do |technology, red_zones|
        {
          technology: technology,
          red_zones: red_zones
        }
      end
    else
      # Group by technology for single team (though usually one technology per red_zone)
      red_zones_data.group_by { |rz| rz[:technology] }.map do |technology, red_zones|
        {
          technology: technology,
          red_zones: red_zones
        }
      end
    end
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
