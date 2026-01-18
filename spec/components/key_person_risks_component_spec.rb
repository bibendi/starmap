# frozen_string_literal: true

require "rails_helper"

RSpec.describe KeyPersonRisksComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }
  let_it_be(:technology3) { create(:technology) }

  describe "#calculate" do
    context "when technologies have multiple experts" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns 0 key person risks" do
        component = described_class.new(team: team)
        expect(component.key_person_risks_count).to eq(0)
      end
    end

    context "when technologies have single expert" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 1 key person risk" do
        component = described_class.new(team: team)
        expect(component.key_person_risks_count).to eq(1)
      end
    end

    context "when multiple technologies have single expert" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology3, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 3 key person risks" do
        component = described_class.new(team: team)
        expect(component.key_person_risks_count).to eq(3)
      end
    end

    context "when team has no technologies" do
      let(:empty_team) { create(:team) }

      it "returns 0 key person risks" do
        component = described_class.new(team: empty_team)
        expect(component.key_person_risks_count).to eq(0)
      end
    end

    context "when there are no skill ratings" do
      before do
        team.technologies << [technology1, technology2]
      end

      it "returns 0 key person risks" do
        component = described_class.new(team: team)
        expect(component.key_person_risks_count).to eq(0)
      end
    end

    context "when there is no current quarter" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        Quarter.destroy_all
      end

      it "returns 0 key person risks" do
        component = described_class.new(team: team)
        expect(component.key_person_risks_count).to eq(0)
      end
    end

    context "when rating is below expert level" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 1, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 1, team: team)
      end

      it "does not count non-expert ratings" do
        component = described_class.new(team: team)
        expect(component.key_person_risks_count).to eq(0)
      end
    end
  end

  describe "rendering" do
    context "with custom label and description" do
      it "renders custom text" do
        component = described_class.new(team: team, label: "Custom Label", description: "Custom Description")
        render_inline(component)
        expect(page).to have_text("Custom Label")
        expect(page).to have_text("Custom Description")
      end
    end

    context "with default label and description" do
      it "renders default text" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Key Person Risks")
        expect(page).to have_text("Риски единоличной экспертизы")
      end
    end

    context "key person risks count display" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "displays count" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("2")
      end
    end

    context "when count is 0" do
      it "displays 0" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("0")
      end
    end
  end
end
