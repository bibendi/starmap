# frozen_string_literal: true

class CoverageIndexComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :coverage_index, :label, :description

  def initialize(team:, label: "Coverage Index", description: "Показатель покрытия технологий")
    @team = team
    @label = label
    @description = description
    @coverage_index = calculate
  end

  private

  def calculate
    technologies = @team.technologies.order(:name)
    return 0 if technologies.empty?

    current_quarter = Quarter.current
    return 0 unless current_quarter

    covered_count = @team.team_technologies.includes(:technology).count do |team_tech|
      expert_count = team_tech.technology.skill_ratings
        .where(quarter: current_quarter, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, team_id: @team.id)
        .count
      expert_count >= team_tech.target_experts
    end

    ((covered_count.to_f / technologies.count) * 100).round
  end
end
