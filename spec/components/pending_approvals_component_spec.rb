# frozen_string_literal: true

require "rails_helper"

RSpec.describe PendingApprovalsComponent, type: :component do
  let_it_be(:team_lead_user) { create(:team_lead) }
  let_it_be(:engineer) { create(:engineer, team: team_lead_user.team) }

  describe "#render?" do
    it "returns true when users present" do
      component = described_class.new(users: [engineer], current_user: team_lead_user)
      expect(component.render?).to be true
    end

    it "returns false when users empty" do
      component = described_class.new(users: [], current_user: team_lead_user)
      expect(component.render?).to be false
    end
  end

  describe "rendering" do
    it "shows title and user names" do
      component = described_class.new(users: [engineer], current_user: team_lead_user)
      render_inline(component)
      expect(page).to have_text(I18n.t("skill_ratings.pending_approvals.title"))
      expect(page).to have_text(engineer.full_name)
    end

    it "shows link to user ratings" do
      component = described_class.new(users: [engineer], current_user: team_lead_user)
      render_inline(component)
      expected_href = Rails.application.routes.url_helpers.user_skill_ratings_path(engineer)
      expect(page).to have_link(I18n.t("skill_ratings.pending_approvals.user_link"), href: expected_href)
    end

    it "shows count badge" do
      component = described_class.new(users: [engineer], current_user: team_lead_user)
      render_inline(component)
      expect(page).to have_css(".badge--danger", text: "1")
    end

    it "lists multiple users" do
      another = create(:engineer, team: team_lead_user.team)
      component = described_class.new(users: [engineer, another], current_user: team_lead_user)
      render_inline(component)
      expect(page).to have_text(engineer.full_name)
      expect(page).to have_text(another.full_name)
    end
  end
end
