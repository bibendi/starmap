# frozen_string_literal: true

require "rails_helper"

RSpec.describe DialogComponent, type: :component do
  let(:stimulus_name) { "test-controller" }

  it "renders dialog element with reusable class" do
    component = described_class.new(stimulus_controller_name: stimulus_name, title: "Test Title")
    render_inline(component)
    expect(page).to have_css("dialog.dialog")
  end

  it "renders title" do
    component = described_class.new(stimulus_controller_name: stimulus_name, title: "Test Title")
    render_inline(component)
    expect(page).to have_css(".dialog__title", text: "Test Title")
  end

  it "renders close button with aria-label" do
    component = described_class.new(stimulus_controller_name: stimulus_name, title: "Test")
    render_inline(component)
    expect(page).to have_css(".dialog__close[aria-label='Close']")
  end

  it "renders close button with custom aria-label" do
    component = described_class.new(stimulus_controller_name: stimulus_name, title: "Test", close_label: "Fermer")
    render_inline(component)
    expect(page).to have_css(".dialog__close[aria-label='Fermer']")
  end

  it "renders close SVG icon" do
    component = described_class.new(stimulus_controller_name: stimulus_name, title: "Test")
    render_inline(component)
    expect(page).to have_css(".dialog__close-icon")
  end

  it "wires close button to stimulus controller" do
    component = described_class.new(stimulus_controller_name: stimulus_name, title: "Test")
    render_inline(component)
    expect(page).to have_css("[data-action='click->test-controller#close']")
  end

  it "wires backdrop click to stimulus controller" do
    component = described_class.new(stimulus_controller_name: stimulus_name, title: "Test")
    render_inline(component)
    expect(page).to have_css("[data-action='click->test-controller#onBackdropClick']")
  end

  it "renders dialog target for stimulus" do
    component = described_class.new(stimulus_controller_name: stimulus_name, title: "Test")
    render_inline(component)
    expect(page).to have_css("[data-test-controller-target='dialog']")
  end

  it "renders body slot content" do
    component = described_class.new(stimulus_controller_name: stimulus_name, title: "Test")
    component.with_body { "<p class='test-body'>Body content</p>".html_safe }
    render_inline(component)
    expect(page).to have_css(".test-body", text: "Body content")
  end
end
