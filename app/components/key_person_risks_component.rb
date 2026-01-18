# frozen_string_literal: true

class KeyPersonRisksComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :key_person_risks_count, :label, :description

  def initialize(team:, label: "Key Person Risks", description: "Риски единоличной экспертизы")
    @team = team
    @label = label
    @description = description
    @key_person_risks_count = calculate
  end

  private

  def calculate
    current_quarter = Quarter.current
    return 0 unless current_quarter

    SkillRating
      .where(quarter: current_quarter, team_id: @team.id, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING)
      .group(:technology_id)
      .having("COUNT(user_id) = 1")
      .count
      .size
  end
end
