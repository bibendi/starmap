# frozen_string_literal: true

class RedZonesCardComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :red_zones_count, :label, :description

  def initialize(teams:, label: nil, description: nil)
    @teams = teams
    @label = label || I18n.t("components.red_zones_card.label")
    @description = description || I18n.t("components.red_zones_card.description")
    @red_zones_count = calculate
  end

  private

  def calculate
    current_quarter = Quarter.current
    return 0 unless current_quarter

    expert_counts_subquery = SkillRating
      .where(quarter: current_quarter, team_id: @teams.map(&:id), rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING)
      .group(:team_id, :technology_id)
      .select("team_id, technology_id, COUNT(*) as expert_count")

    TeamTechnology
      .where(team_id: @teams.map(&:id))
      .joins("LEFT JOIN (#{expert_counts_subquery.to_sql}) expert_counts ON expert_counts.team_id = team_technologies.team_id AND expert_counts.technology_id = team_technologies.technology_id")
      .where(criticality: [:normal, :high])
      .where("COALESCE(expert_counts.expert_count, 0) < team_technologies.target_experts")
      .count
  end
end
