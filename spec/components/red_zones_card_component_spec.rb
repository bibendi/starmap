# frozen_string_literal: true

require "rails_helper"

RSpec.describe RedZonesCardComponent, type: :component do
  let_it_be(:team) { create(:team) }

  describe "rendering" do
    context "with custom label and description" do
      it "renders custom text" do
        component = described_class.new(red_zones_count: 0, label: "Custom Label", description: "Custom Description")
        render_inline(component)
        expect(page).to have_text("Custom Label")
        expect(page).to have_text("Custom Description")
      end
    end

    context "with default label and description" do
      it "renders default text" do
        component = described_class.new(red_zones_count: 0)
        render_inline(component)
        expect(page).to have_text("Red Zones")
        expect(page).to have_text("Critical competencies without coverage")
      end
    end

    context "red zones count display" do
      it "displays count" do
        component = described_class.new(red_zones_count: 1)
        render_inline(component)
        expect(page).to have_text("1")
      end
    end

    context "when count is 0" do
      it "displays 0" do
        component = described_class.new(red_zones_count: 0)
        render_inline(component)
        expect(page).to have_text("0")
      end
    end
  end
end
