# frozen_string_literal: true

class UnitTechnologyTreemapQuery
  def initialize(teams:, assessment_period: AssessmentPeriod.current)
    @teams = teams
    @assessment_period = assessment_period
  end

  def data
    return [] unless @assessment_period

    team_technologies = TeamTechnology.includes(:technology).active.where(team_id: team_ids)
    technology_ids = team_technologies.pluck(:technology_id).uniq

    return [] if technology_ids.empty?

    experts_by_tech_team = SkillRating
      .visible_for_assessment_period(@assessment_period)
      .expert_ratings
      .where(assessment_period: @assessment_period, technology_id: technology_ids, team_id: team_ids)
      .group(:technology_id, :team_id)
      .count

    build_technologies_data(technology_ids, team_technologies, experts_by_tech_team)
  end

  private

  def team_ids
    @teams.map(&:id)
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

    {
      technology: tech_team_records.first.technology,
      expert_count: metrics[:total_experts],
      all_teams_in_target: metrics[:all_teams_in_target],
      deficit: metrics[:total_deficit]
    }
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
end
