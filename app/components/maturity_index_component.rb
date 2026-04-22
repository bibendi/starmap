# frozen_string_literal: true

class MaturityIndexComponent < ViewComponent::Base
  attr_reader :maturity_index, :team_ids, :label, :description

  def initialize(maturity_index:, team_ids:, label: nil, description: nil)
    @maturity_index = maturity_index
    @team_ids = team_ids
    @label = label || I18n.t("components.maturity_index.label")
    @description = description || I18n.t("components.maturity_index.description")
  end
end
