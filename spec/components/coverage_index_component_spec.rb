# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoverageIndexComponent, type: :component do
  let_it_be(:team) { create(:team) }

  describe "rendering" do
    context "with custom label and description" do
      it "renders custom text" do
        component = described_class.new(coverage_index: 50, team_ids: [team.id], label: "Custom Label", description: "Custom Description")
        render_inline(component)
        expect(page).to have_text("Custom Label")
        expect(page).to have_text("Custom Description")
      end
    end

    context "with default label and description" do
      it "renders default text" do
        component = described_class.new(coverage_index: 0, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_text("Coverage Index")
        expect(page).to have_text("Competency coverage indicator")
      end
    end

    context "CSS classes" do
      it "applies correct component classes" do
        component = described_class.new(coverage_index: 0, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css(".metric-card")
        expect(page).to have_css(".metric-card--primary")
      end
    end

    context "coverage value display" do
      it "displays percentage" do
        component = described_class.new(coverage_index: 50, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_text("50%")
      end
    end

    context "interactive elements" do
      it "renders data-controller for stimulus" do
        component = described_class.new(coverage_index: 50, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css("[data-controller='coverage-index-history']")
      end

      it "renders team_ids as stimulus value" do
        component = described_class.new(coverage_index: 50, team_ids: [team.id, 99])
        render_inline(component)
        expect(page).to have_css("[data-coverage-index-history-team-ids-value]")
      end

      it "renders dialog element with reusable class" do
        component = described_class.new(coverage_index: 50, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css("dialog.dialog")
      end

      it "renders click action on wrapper" do
        component = described_class.new(coverage_index: 50, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css("[data-action*='coverage-index-history#open']")
      end

      it "renders aria-haspopup" do
        component = described_class.new(coverage_index: 50, team_ids: [team.id])
        render_inline(component)
        expect(page).to have_css('[aria-haspopup="dialog"]')
      end
    end
  end
end
