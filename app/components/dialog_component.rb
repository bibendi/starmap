# frozen_string_literal: true

class DialogComponent < ViewComponent::Base
  renders_one :body

  def initialize(stimulus_controller_name:, title:, close_label: nil)
    @stimulus_controller_name = stimulus_controller_name
    @title = title
    @close_label = close_label || I18n.t("components.dialog.close")
  end

  private

  attr_reader :stimulus_controller_name, :title, :close_label
end
