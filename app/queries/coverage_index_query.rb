# frozen_string_literal: true

class CoverageIndexQuery
  def initialize(teams:, quarter: Quarter.current)
    @teams = teams
    @quarter = quarter
  end

  def percentage
    team_technologies = TeamTechnology.includes(:technology).where(team_id: team_ids)
    return 0 if team_technologies.empty?
    return 0 unless @quarter

    expert_counts = SkillRating
      .visible_for_quarter(@quarter)
      .expert_ratings
      .where(quarter: @quarter, team_id: team_ids)
      .group(:team_id, :technology_id)
      .count
      .transform_keys { |k| "#{k[0]}-#{k[1]}" }

    covered_count = team_technologies.count do |team_tech|
      key = "#{team_tech.team_id}-#{team_tech.technology_id}"
      expert_count = expert_counts[key] || 0
      expert_count >= team_tech.target_experts
    end

    ((covered_count.to_f / team_technologies.size) * 100).round
  end

  private

  def team_ids
    @teams.map(&:id)
  end
end
