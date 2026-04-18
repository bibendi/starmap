# frozen_string_literal: true

class RedZonesQuery
  def initialize(teams:, quarter: Quarter.current)
    @teams = teams
    @quarter = quarter
  end

  def count
    return 0 unless @quarter

    expert_counts_subquery = SkillRating
      .visible_for_quarter(@quarter)
      .expert_ratings
      .where(quarter: @quarter, team_id: team_ids)
      .group(:team_id, :technology_id)
      .select("team_id, technology_id, COUNT(*) as expert_count")

    TeamTechnology
      .where(team_id: team_ids)
      .critical
      .joins("LEFT JOIN (#{expert_counts_subquery.to_sql}) expert_counts ON expert_counts.team_id = team_technologies.team_id AND expert_counts.technology_id = team_technologies.technology_id")
      .where("COALESCE(expert_counts.expert_count, 0) = 0")
      .count
  end

  def details
    return [] unless @quarter

    team_technologies = TeamTechnology
      .includes(:technology, :team)
      .critical
      .where(team_id: team_ids)

    expert_ratings = SkillRating
      .preload(:user)
      .visible_for_quarter(@quarter)
      .expert_ratings
      .where(
        quarter: @quarter,
        technology_id: team_technologies.map(&:technology_id),
        team_id: team_ids
      )

    experts_by_tech_team = expert_ratings.each_with_object({}) do |rating, hash|
      key = [rating.technology_id, rating.team_id]
      hash[key] ||= []
      hash[key] << rating.user
    end

    team_technologies.each_with_object([]) do |team_tech, result|
      key = [team_tech.technology_id, team_tech.team_id]
      experts = experts_by_tech_team[key] || []
      expert_count = experts.size

      next unless expert_count.zero?

      result << {
        technology: team_tech.technology,
        team: team_tech.team,
        expert_count: expert_count,
        target_experts: team_tech.target_experts,
        deficit: team_tech.target_experts - expert_count,
        experts: experts
      }
    end.sort_by { |red_zone| red_zone[:technology]&.name || "" }
  end

  private

  def team_ids
    @teams.map(&:id)
  end
end
