# frozen_string_literal: true

class UnitTechnologyTreemapComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :technologies_data, :teams, :max_experts, :max_deficit

  def initialize(teams:)
    @teams = teams
    @technologies_data = calculate
    @max_experts = max_value(:expert_count)
    @max_deficit = max_value(:deficit)
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
        category: tech[:technology]&.category&.name,
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
    team_technologies = fetch_team_technologies(team_ids)
    technology_ids = team_technologies.pluck(:technology_id).uniq

    return [] if technology_ids.empty?

    experts_by_tech_team = fetch_experts_by_tech_team(current_quarter, technology_ids, team_ids)
    build_technologies_data(technology_ids, team_technologies, experts_by_tech_team)
  end

  def fetch_team_technologies(team_ids)
    TeamTechnology.includes(:technology).where(team_id: team_ids)
  end

  def fetch_experts_by_tech_team(quarter, technology_ids, team_ids)
    SkillRating
      .visible_for_quarter(quarter)
      .where(quarter: quarter, technology_id: technology_ids, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, team_id: team_ids)
      .group(:technology_id, :team_id)
      .count
  end

  def build_technologies_data(technology_ids, team_technologies, experts_by_tech_team)
    technologies = technology_ids.filter_map do |tech_id|
      calculate_technology_metrics(tech_id, team_technologies, experts_by_tech_team)
    end

    technologies.sort_by { |t| -t[:expert_count] }
  end

  def calculate_technology_metrics(tech_id, team_technologies, experts_by_tech_team)
    tech_team_records = team_technologies.select { |tt| tt.technology_id == tech_id }
    return nil if tech_team_records.empty?

    metrics = aggregate_team_metrics(tech_team_records, tech_id, experts_by_tech_team)
    return nil if metrics[:total_experts].zero?

    build_technology_hash(tech_team_records.first, metrics)
  end

  def aggregate_team_metrics(tech_team_records, tech_id, experts_by_tech_team)
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

    {total_experts: total_experts, total_deficit: total_deficit, all_teams_in_target: all_teams_in_target}
  end

  def build_technology_hash(first_record, metrics)
    {
      technology: first_record.technology,
      expert_count: metrics[:total_experts],
      all_teams_in_target: metrics[:all_teams_in_target],
      deficit: metrics[:total_deficit]
    }
  end

  def max_value(key)
    [@technologies_data.pluck(key).max, 1].compact.max
  end
end
