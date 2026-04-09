# frozen_string_literal: true

class CoverageIndexComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :coverage_index, :label, :description

  def initialize(teams:, label: nil, description: nil)
    @teams = teams
    @label = label || I18n.t("components.coverage_index.label")
    @description = description || I18n.t("components.coverage_index.description")
    @coverage_index = calculate
  end

  private

  def calculate
    team_technologies = TeamTechnology.includes(:technology).where(team_id: @teams)
    return 0 if team_technologies.empty?

    current_quarter = Quarter.current
    return 0 unless current_quarter

    team_ids = @teams.map(&:id)

    expert_counts = SkillRating
      .where(quarter: current_quarter,
        rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING,
        team_id: team_ids,
        status: :approved)
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
end
