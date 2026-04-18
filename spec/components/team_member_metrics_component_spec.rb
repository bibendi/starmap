# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamMemberMetricsComponent, type: :component do
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }

  describe "#any_data?" do
    it "returns false when all metrics are zero" do
      metrics = {
        user1.id => {
          competence_level: {total: 0, high: 0, normal: 0, low: 0},
          universality: {total: 0, high: 0, normal: 0, low: 0},
          expertise_concentration: {total: 0, high: 0, normal: 0, low: 0}
        }
      }
      component = described_class.new(team: team, team_members: [user1], team_member_metrics: metrics)
      expect(component.any_data?).to be false
    end

    it "returns true when some metrics are positive" do
      metrics = {
        user1.id => {
          competence_level: {total: 3, high: 0, normal: 0, low: 0},
          universality: {total: 0, high: 0, normal: 0, low: 0},
          expertise_concentration: {total: 0, high: 0, normal: 0, low: 0}
        }
      }
      component = described_class.new(team: team, team_members: [user1], team_member_metrics: metrics)
      expect(component.any_data?).to be true
    end
  end

  describe "rendering" do
    context "when there is no data" do
      it "renders empty state message" do
        component = described_class.new(team: team, team_members: [user1], team_member_metrics: {})
        render_inline(component)
        expect(page).to have_text("No team member metrics data")
      end
    end

    context "when there is data" do
      let(:metrics) do
        {
          user1.id => {
            competence_level: {total: 6, high: 3, normal: 2, low: 1},
            universality: {total: 2, high: 1, normal: 1, low: 0},
            expertise_concentration: {total: 0, high: 0, normal: 0, low: 0}
          },
          user2.id => {
            competence_level: {total: 3, high: 3, normal: 0, low: 0},
            universality: {total: 1, high: 1, normal: 0, low: 0},
            expertise_concentration: {total: 0, high: 0, normal: 0, low: 0}
          }
        }
      end

      it "renders the table header" do
        component = described_class.new(team: team, team_members: [user1, user2], team_member_metrics: metrics)
        render_inline(component)
        expect(page).to have_text("Team Member Metrics")
        expect(page).to have_text("Competency level, universality and expertise concentration by competency criticality")
      end

      it "renders user first names" do
        component = described_class.new(team: team, team_members: [user1, user2], team_member_metrics: metrics)
        render_inline(component)
        expect(page).to have_text(user1.full_name.split.first)
        expect(page).to have_text(user2.full_name.split.first)
      end

      it "renders competence level section" do
        component = described_class.new(team: team, team_members: [user1, user2], team_member_metrics: metrics)
        render_inline(component)
        expect(page).to have_text("Competence Level")
        expect(page).to have_text("Total")
      end

      it "renders universality section" do
        component = described_class.new(team: team, team_members: [user1, user2], team_member_metrics: metrics)
        render_inline(component)
        expect(page).to have_text("Universality")
      end

      it "renders expertise concentration section" do
        component = described_class.new(team: team, team_members: [user1, user2], team_member_metrics: metrics)
        render_inline(component)
        expect(page).to have_text("Expertise Concentration")
      end

      it "renders metric values" do
        component = described_class.new(team: team, team_members: [user1, user2], team_member_metrics: metrics)
        render_inline(component)
        expect(page).to have_text("3")
        expect(page).to have_text("2")
        expect(page).to have_text("1")
      end
    end

    context "when there are changes from previous quarter" do
      let(:metrics_with_changes) do
        {
          user1.id => {
            competence_level: {total: 6, high: 3, normal: 2, low: 1, total_change: 2, high_change: 1, normal_change: 1, low_change: 0},
            universality: {total: 2, high: 1, normal: 1, low: 0, total_change: 1, high_change: 0, normal_change: 1, low_change: 0},
            expertise_concentration: {total: 0, high: 0, normal: 0, low: 0, total_change: 0, high_change: 0, normal_change: 0, low_change: 0}
          }
        }
      end

      it "renders change indicators" do
        component = described_class.new(team: team, team_members: [user1], team_member_metrics: metrics_with_changes)
        render_inline(component)
        expect(page).to have_text("+1")
      end
    end
  end
end
