# frozen_string_literal: true

class UnitTechnologyTreemapComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :technologies_data, :teams, :max_experts, :max_deficit

  def initialize(teams:)
    @teams = teams
    @technologies_data = calculate
    # rubocop:disable Rails/Pluck
    @max_experts = @technologies_data.map { |t| t[:expert_count] }.max || 1
    @max_deficit = @technologies_data.map { |t| t[:deficit] }.max || 1
    # rubocop:enable Rails/Pluck
  end

  def any_technologies?
    technologies_data.any?
  end

  def technologies_count
    technologies_data.size
  end

  def intensity_for_experts(count)
    return 1 if max_experts <= 1
    normalized = (count.to_f / max_experts * 4).round + 1
    [normalized, 5].min
  end

  def intensity_for_deficit(deficit)
    return 1 if max_deficit <= 1
    normalized = (deficit.to_f / max_deficit * 4).round + 1
    [normalized, 5].min
  end

  # Prepare data for Chart.js treemap
  def chart_data
    technologies_data.map do |tech|
      {
        name: tech[:technology]&.name,
        category: tech[:technology]&.category,
        value: tech[:expert_count],
        allTeamsInTarget: tech[:all_teams_in_target],
        intensity: intensity_for_experts(tech[:expert_count]),
        deficitIntensity: intensity_for_deficit(tech[:deficit])
      }
    end
  end

  private

  def calculate
    current_quarter = Quarter.current
    return [] unless current_quarter

    team_ids = @teams.map(&:id)

    team_technologies = TeamTechnology
      .includes(:technology)
      .where(team_id: team_ids)

    technology_ids = team_technologies.map(&:technology_id).uniq

    return [] if technology_ids.empty?

    expert_ratings = SkillRating
      .where(
        quarter: current_quarter,
        technology_id: technology_ids,
        rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING,
        team_id: team_ids
      )

    experts_by_tech_team = expert_ratings
      .group(:technology_id, :team_id)
      .count

    technologies = technology_ids.map do |tech_id|
      tech_team_records = team_technologies.select { |tt| tt.technology_id == tech_id }
      next if tech_team_records.empty?

      total_experts = 0
      total_deficit = 0
      all_teams_in_target = true

      tech_team_records.each do |team_tech|
        expert_count = experts_by_tech_team[[tech_id, team_tech.team_id]] || 0
        total_experts += expert_count

        if expert_count < team_tech.target_experts
          all_teams_in_target = false
          total_deficit += (team_tech.target_experts - expert_count)
        end
      end

      next if total_experts == 0

      {
        technology: tech_team_records.first.technology,
        expert_count: total_experts,
        all_teams_in_target: all_teams_in_target,
        deficit: total_deficit
      }
    end.compact

    technologies.sort_by { |t| -t[:expert_count] }
  end
end
