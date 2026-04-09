# frozen_string_literal: true

class MaturityIndexComponent < ViewComponent::Base
  attr_reader :maturity_index, :label, :description

  def initialize(teams:, label: nil, description: nil)
    @teams = teams
    @label = label || I18n.t("components.maturity_index.label")
    @description = description || I18n.t("components.maturity_index.description")
    @maturity_index = calculate
  end

  private

  def calculate
    current_quarter = Quarter.current
    return 0 unless current_quarter

    ratings = SkillRating.where(team_id: @teams.map(&:id), quarter: current_quarter, status: :approved)
    ratings.average(:rating)&.round(1) || 0
  end
end
