# frozen_string_literal: true

require "rails_helper"

RSpec.describe KeyPersonRisksComponent, type: :component do
  describe "rendering" do
    context "with custom label and description" do
      it "renders custom text" do
        component = described_class.new(key_person_risks_count: 0, label: "Custom Label", description: "Custom Description")
        render_inline(component)
        expect(page).to have_text("Custom Label")
        expect(page).to have_text("Custom Description")
      end
    end

    context "with default label and description" do
      it "renders default text" do
        component = described_class.new(key_person_risks_count: 0)
        render_inline(component)
        expect(page).to have_text("Key Person Risks")
        expect(page).to have_text("Single expert risks")
      end
    end

    context "key person risks count display" do
      it "displays count" do
        component = described_class.new(key_person_risks_count: 2)
        render_inline(component)
        expect(page).to have_text("2")
      end
    end

    context "when count is 0" do
      it "displays 0" do
        component = described_class.new(key_person_risks_count: 0)
        render_inline(component)
        expect(page).to have_text("0")
      end
    end
  end
end
