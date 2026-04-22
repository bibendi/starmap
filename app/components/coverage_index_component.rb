# frozen_string_literal: true

class CoverageIndexComponent < ViewComponent::Base
  attr_reader :coverage_index, :team_ids, :label, :description

  def initialize(coverage_index:, team_ids:, label: nil, description: nil)
    @coverage_index = coverage_index
    @team_ids = team_ids
    @label = label || I18n.t("components.coverage_index.label")
    @description = description || I18n.t("components.coverage_index.description")
  end
end
