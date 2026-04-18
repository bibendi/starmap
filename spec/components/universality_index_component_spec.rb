# frozen_string_literal: true

require "rails_helper"

RSpec.describe UniversalityIndexComponent, type: :component do
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }

  describe "rendering" do
    context "with expert ratings" do
      it "displays user name and competency count" do
        index = {user1.id => 2}
        component = described_class.new(universality_index: index, team_members: [user1])
        render_inline(component)
        expect(page).to have_text(user1.full_name)
        expect(page).to have_text("2 competencies")
      end
    end

    context "with no data" do
      it "renders the card with empty body" do
        component = described_class.new(universality_index: {}, team_members: [])
        render_inline(component)
        expect(page).to have_text("Universality Index")
      end
    end
  end
end
