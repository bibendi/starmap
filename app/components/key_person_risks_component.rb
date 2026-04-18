# frozen_string_literal: true

class KeyPersonRisksComponent < ViewComponent::Base
  attr_reader :key_person_risks_count, :label, :description

  def initialize(key_person_risks_count:, label: nil, description: nil)
    @key_person_risks_count = key_person_risks_count
    @label = label || I18n.t("components.key_person_risks.label")
    @description = description || I18n.t("components.key_person_risks.description")
  end
end
