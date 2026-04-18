# frozen_string_literal: true

require "rails_helper"

RSpec.describe MaturityIndexComponent, type: :component do
  describe "rendering" do
    context "with custom label and description" do
      it "renders custom text" do
        component = described_class.new(maturity_index: 0, label: "Custom Label", description: "Custom Description")
        render_inline(component)
        expect(page).to have_text("Custom Label")
        expect(page).to have_text("Custom Description")
      end
    end

    context "with default label and description" do
      it "renders default text" do
        component = described_class.new(maturity_index: 0)
        render_inline(component)
        expect(page).to have_text("Maturity Index")
        expect(page).to have_text("Competency maturity level")
      end
    end

    context "maturity value display" do
      it "displays value with max scale" do
        component = described_class.new(maturity_index: 2.5)
        render_inline(component)
        expect(page).to have_text("2.5/3.0")
      end
    end

    context "when maturity index is 0" do
      it "displays 0/3.0" do
        component = described_class.new(maturity_index: 0)
        render_inline(component)
        expect(page).to have_text("0/3.0")
      end
    end
  end
end
