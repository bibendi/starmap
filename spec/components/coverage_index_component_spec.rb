# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoverageIndexComponent, type: :component do
  describe "rendering" do
    context "with custom label and description" do
      it "renders custom text" do
        component = described_class.new(coverage_index: 50, label: "Custom Label", description: "Custom Description")
        render_inline(component)
        expect(page).to have_text("Custom Label")
        expect(page).to have_text("Custom Description")
      end
    end

    context "with default label and description" do
      it "renders default text" do
        component = described_class.new(coverage_index: 0)
        render_inline(component)
        expect(page).to have_text("Coverage Index")
        expect(page).to have_text("Competency coverage indicator")
      end
    end

    context "CSS classes" do
      it "applies correct component classes" do
        component = described_class.new(coverage_index: 0)
        render_inline(component)
        expect(page).to have_css(".metric-card")
        expect(page).to have_css(".metric-card--primary")
      end
    end

    context "coverage value display" do
      it "displays percentage" do
        component = described_class.new(coverage_index: 50)
        render_inline(component)
        expect(page).to have_text("50%")
      end
    end
  end
end
