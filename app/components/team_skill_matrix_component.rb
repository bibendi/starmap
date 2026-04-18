# frozen_string_literal: true

class TeamSkillMatrixComponent < ViewComponent::Base
  attr_reader :team, :team_skill_matrix, :team_members, :technologies, :bus_factor, :rating_dynamics

  def initialize(team:, team_members:, technologies:, bus_factor:, skill_matrix:, rating_dynamics:, show_technology_links: false)
    @team = team
    @team_members = team_members
    @technologies = technologies
    @bus_factor = bus_factor
    @team_skill_matrix = skill_matrix
    @rating_dynamics = rating_dynamics
    @show_technology_links = show_technology_links
  end

  def show_technology_links?
    @show_technology_links
  end

  def any_data?
    return false unless @team_members.any?

    @team_skill_matrix.values.any? { |user_ratings| user_ratings.values.any?(&:positive?) }
  end

  def bus_factor_for(technology_id)
    @bus_factor[technology_id]
  end

  def coverage_for(technology_id)
    bus_factor_data = @bus_factor[technology_id]
    return 0 unless bus_factor_data

    total = @team_members.size
    return 0 if total.zero?

    [(bus_factor_data[:count].to_f / total * 100).round, 100].min
  end

  def rating_for(technology_id, user_id)
    @team_skill_matrix.dig(technology_id, user_id) || 0
  end

  def change_for(technology_id, user_id)
    @rating_dynamics.dig(technology_id, user_id)
  end

  def technology_for(technology_id)
    @technologies_by_id ||= @technologies.to_h { |t| [t.id, t] }
    @technologies_by_id[technology_id]
  end

  private

  def team_technology_link_for(technology)
    @team_technologies_by_id ||= @team.team_technologies.to_h { |tt| [tt.technology_id, tt] }
    @team_technologies_by_id[technology.id]
  end
end
