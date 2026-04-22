# frozen_string_literal: true

require "rails_helper"

RSpec.describe MaturityIndexComponent, type: :component do
  let_it_be(:team) { create(:team) }

  describe "rendering" do
    context "with custom label and description" do
      it "renders custom text" do
        component = described_class.new(maturity_index: 0, team_ids: [team.id], label: "Custom Label", description: "Custom Description")
        render_inline(component)
        expect(page).to have_text("Custom Label")
        expect(page).to have_text("Custom Description")
      end
    end

    context "with default label and description" do
      it "renders default text" do
        component = described_class.new(maturity_index: 0, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_text("Maturity Index")
        expect(page).to have_text("Competency maturity level")
      end
    end

    context "maturity value display" do
      it "displays value with max scale" do
        component = described_class.new(maturity_index: 2.5, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_text("2.5/3.0")
      end
    end

    context "when maturity index is 0" do
      it "displays 0/3.0" do
        component = described_class.new(maturity_index: 0, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_text("0/3.0")
      end
    end

    context "CSS classes" do
      it "applies correct component classes" do
        component = described_class.new(maturity_index: 0, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css(".metric-card")
        expect(page).to have_css(".metric-card--secondary")
      end
    end

    context "interactive elements" do
      it "renders data-controller for stimulus" do
        component = described_class.new(maturity_index: 2.5, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css("[data-controller='maturity-index-history']")
      end

      it "renders team_ids as stimulus value" do
        component = described_class.new(maturity_index: 2.5, team_ids: [team.id, 99])
        render_inline(component)
        expect(page).to have_css("[data-maturity-index-history-team-ids-value]")
      end

      it "renders dialog element with reusable class" do
        component = described_class.new(maturity_index: 2.5, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css("dialog.dialog")
      end

      it "renders click action on wrapper" do
        component = described_class.new(maturity_index: 2.5, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css("[data-action*='maturity-index-history#open']")
      end

      it "renders aria-haspopup" do
        component = described_class.new(maturity_index: 2.5, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css('[aria-haspopup="dialog"]')
      end
    end
  end
end
