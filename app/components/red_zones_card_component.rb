# frozen_string_literal: true

class RedZonesCardComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :red_zones_count, :label, :description

  def initialize(team:, label: nil, description: nil)
    @team = team
    @label = label || I18n.t('components.red_zones_card.label')
    @description = description || I18n.t('components.red_zones_card.description')
    @red_zones_count = calculate
  end

  private

  def calculate
    current_quarter = Quarter.current
    return 0 unless current_quarter

    expert_counts_subquery = SkillRating
      .where(quarter: current_quarter, team_id: @team.id, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING)
      .group(:technology_id)
      .select('technology_id, COUNT(*) as expert_count')

    @team.team_technologies
      .joins("LEFT JOIN (#{expert_counts_subquery.to_sql}) expert_counts ON expert_counts.technology_id = team_technologies.technology_id")
      .where(criticality: [:normal, :high])
      .where('COALESCE(expert_counts.expert_count, 0) < team_technologies.target_experts')
      .count
  end
end
