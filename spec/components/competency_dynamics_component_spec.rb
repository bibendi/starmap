# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompetencyDynamicsComponent, type: :component do
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }

  describe "rendering" do
    context "with positive dynamics" do
      it "displays user name and positive change" do
        dynamics = {user1.id => 2}
        component = described_class.new(competency_dynamics: dynamics, team_members: [user1])
        render_inline(component)
        expect(page).to have_text(user1.full_name)
        expect(page).to have_text("+2")
        expect(page).to have_css(".badge--success")
      end
    end

    context "with negative dynamics" do
      it "displays negative change with red badge" do
        dynamics = {user1.id => -2}
        component = described_class.new(competency_dynamics: dynamics, team_members: [user1])
        render_inline(component)
        expect(page).to have_text("-2")
        expect(page).to have_css(".badge--danger")
      end
    end

    context "when no dynamics data" do
      it "displays empty state message" do
        component = described_class.new(competency_dynamics: {}, team_members: [])
        render_inline(component)
        expect(page).to have_text("No competency dynamics data")
      end
    end

    context "title and description" do
      it "displays correct title" do
        component = described_class.new(competency_dynamics: {}, team_members: [])
        render_inline(component)
        expect(page).to have_text("Competency Dynamics")
        expect(page).to have_text("Skill changes compared to previous quarter")
      end
    end
  end
end
