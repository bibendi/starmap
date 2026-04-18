# frozen_string_literal: true

require "rails_helper"

RSpec.describe KeyPersonRisksDetailsComponent, type: :component do
  let_it_be(:team) { create(:team) }
  let_it_be(:technology1) { create(:technology, name: "Ruby", category_name: "Backend") }
  let_it_be(:technology2) { create(:technology, name: "PostgreSQL", category_name: "Database") }
  let_it_be(:user1) { create(:user, team: team, first_name: "John", last_name: "Doe") }

  describe "#any_risks?" do
    it "returns true when risks exist" do
      component = described_class.new(teams: [team], risks_data: [
        {technology: technology1, team: team, user: user1}
      ])
      expect(component.any_risks?).to be true
    end

    it "returns false when no risks" do
      component = described_class.new(teams: [team], risks_data: [])
      expect(component.any_risks?).to be false
    end
  end

  describe "rendering" do
    context "when there are key person risks" do
      let(:risks_data) do
        [
          {technology: technology1, team: team, user: user1},
          {technology: technology2, team: team, user: user1}
        ]
      end

      it "renders technology names" do
        component = described_class.new(teams: [team], risks_data: risks_data)
        render_inline(component)
        expect(page).to have_text("Ruby")
        expect(page).to have_text("PostgreSQL")
      end

      it "renders user names" do
        component = described_class.new(teams: [team], risks_data: risks_data)
        render_inline(component)
        expect(page).to have_text("John Doe")
      end

      it "renders header" do
        component = described_class.new(teams: [team], risks_data: risks_data)
        render_inline(component)
        expect(page).to have_text("Key Person Risks")
        expect(page).to have_text("2 competencies with single expert")
      end
    end

    context "when there are no key person risks" do
      it "renders empty state message" do
        component = described_class.new(teams: [team], risks_data: [])
        render_inline(component)
        expect(page).to have_text("No key person risks detected")
      end
    end
  end
end
