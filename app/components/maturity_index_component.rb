# frozen_string_literal: true

class MaturityIndexComponent < ViewComponent::Base
  attr_reader :maturity_index, :label, :description

  def initialize(maturity_index:, label: nil, description: nil)
    @maturity_index = maturity_index
    @label = label || I18n.t("components.maturity_index.label")
    @description = description || I18n.t("components.maturity_index.description")
  end
end
