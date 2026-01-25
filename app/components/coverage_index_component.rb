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
    team_technologies = @team.team_technologies.includes(:technology)
    return 0 if team_technologies.empty?

    current_quarter = Quarter.current
    return 0 unless current_quarter

    technology_ids = team_technologies.map(&:technology_id)
    
    expert_counts = SkillRating
      .where(quarter: current_quarter, 
             rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, 
             team_id: @team.id, 
             technology_id: technology_ids)
      .group(:technology_id)
      .count

    covered_count = team_technologies.count do |team_tech|
      expert_count = expert_counts[team_tech.technology_id] || 0
      expert_count >= team_tech.target_experts
    end

    ((covered_count.to_f / team_technologies.size) * 100).round
  end
end
