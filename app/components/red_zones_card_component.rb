# frozen_string_literal: true

class RedZonesCardComponent < ViewComponent::Base
  attr_reader :red_zones_count, :label, :description

  def initialize(red_zones_count:, label: nil, description: nil)
    @red_zones_count = red_zones_count
    @label = label || I18n.t("components.red_zones_card.label")
    @description = description || I18n.t("components.red_zones_card.description")
  end
end
