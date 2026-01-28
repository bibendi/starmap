# frozen_string_literal: true

class MaturityIndexComponent < ViewComponent::Base
  attr_reader :maturity_index, :label, :description

  def initialize(team:, label: nil, description: nil)
    @team = team
    @label = label || I18n.t("components.maturity_index.label")
    @description = description || I18n.t("components.maturity_index.description")
    @maturity_index = calculate
  end

  private

  def calculate
    current_quarter = Quarter.current
    return 0 unless current_quarter

    ratings = SkillRating.where(team_id: @team.id, quarter: current_quarter)
    ratings.average(:rating)&.round(1) || 0
  end
end
