# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamSkillMatrixComponent, type: :component do
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology, name: "Ruby", category_name: "Backend") }
  let_it_be(:technology2) { create(:technology, name: "React", category_name: "Frontend") }
  let_it_be(:technology3) { create(:technology, name: "PostgreSQL", category_name: "Database") }

  let(:technologies) { [technology1, technology2, technology3] }
  let(:team_members) { [user1, user2] }
  let(:default_bus_factor) do
    {
      technology1.id => {count: 0, target: 2, risk_level: "high", criticality: "high"},
      technology2.id => {count: 0, target: 2, risk_level: "high", criticality: "normal"},
      technology3.id => {count: 0, target: 1, risk_level: "high", criticality: "low"}
    }
  end
  let(:default_skill_matrix) do
    {
      technology1.id => {user1.id => 0, user2.id => 0},
      technology2.id => {user1.id => 0, user2.id => 0},
      technology3.id => {user1.id => 0, user2.id => 0}
    }
  end
  let(:default_dynamics) { {} }

  def build_component(overrides = {})
    args = {
      team: team,
      team_members: team_members,
      technologies: technologies,
      bus_factor: default_bus_factor,
      skill_matrix: default_skill_matrix,
      rating_dynamics: default_dynamics,
      show_technology_links: false
    }.merge(overrides)
    described_class.new(**args)
  end

  describe "#any_data?" do
    it "returns false when all ratings are zero" do
      component = build_component
      expect(component.any_data?).to be false
    end

    it "returns true when some ratings are positive" do
      matrix = {technology1.id => {user1.id => 2, user2.id => 0}}
      component = build_component(skill_matrix: matrix)
      expect(component.any_data?).to be true
    end
  end

  describe "#bus_factor_for" do
    it "returns bus factor data for a technology" do
      component = build_component
      expect(component.bus_factor_for(technology1.id)[:risk_level]).to eq("high")
      expect(component.bus_factor_for(technology1.id)[:count]).to eq(0)
    end
  end

  describe "#coverage_for" do
    it "returns 0 when no experts" do
      component = build_component
      expect(component.coverage_for(technology1.id)).to eq(0)
    end

    it "returns 50 for partial coverage" do
      bus_factor = default_bus_factor.merge(
        technology1.id => {count: 1, target: 2, risk_level: "medium", criticality: "high"}
      )
      component = build_component(bus_factor: bus_factor)
      expect(component.coverage_for(technology1.id)).to eq(50)
    end

    it "caps at 100" do
      bus_factor = default_bus_factor.merge(
        technology3.id => {count: 2, target: 1, risk_level: "low", criticality: "low"}
      )
      component = build_component(bus_factor: bus_factor)
      expect(component.coverage_for(technology3.id)).to eq(100)
    end
  end

  describe "#rating_for" do
    it "returns rating from matrix" do
      matrix = {technology1.id => {user1.id => 3, user2.id => 1}}
      component = build_component(skill_matrix: matrix)
      expect(component.rating_for(technology1.id, user1.id)).to eq(3)
      expect(component.rating_for(technology1.id, user2.id)).to eq(1)
    end

    it "returns 0 for missing rating" do
      component = build_component
      expect(component.rating_for(technology1.id, user1.id)).to eq(0)
    end
  end

  describe "#change_for" do
    it "returns change from dynamics" do
      dynamics = {technology1.id => {user1.id => 1}}
      component = build_component(rating_dynamics: dynamics)
      expect(component.change_for(technology1.id, user1.id)).to eq(1)
    end

    it "returns nil for missing dynamics" do
      component = build_component
      expect(component.change_for(technology1.id, user1.id)).to be_nil
    end
  end

  describe "rendering" do
    context "when there is no data" do
      it "renders empty state message" do
        component = build_component(team_members: [])
        render_inline(component)
        expect(page).to have_text("No team skill data")
      end
    end

    context "when there is data" do
      let(:matrix_with_data) do
        {
          technology1.id => {user1.id => 2, user2.id => 3},
          technology2.id => {user1.id => 1, user2.id => 0},
          technology3.id => {user1.id => 0, user2.id => 0}
        }
      end
      let(:bus_factor_with_data) do
        {
          technology1.id => {count: 2, target: 2, risk_level: "low", criticality: "high"},
          technology2.id => {count: 0, target: 2, risk_level: "high", criticality: "normal"},
          technology3.id => {count: 0, target: 1, risk_level: "high", criticality: "low"}
        }
      end

      it "renders the table header" do
        component = build_component(skill_matrix: matrix_with_data, bus_factor: bus_factor_with_data)
        render_inline(component)
        expect(page).to have_text("Competency")
        expect(page).to have_text("Bus Factor")
        expect(page).to have_text("Coverage")
      end

      it "renders technology names as links when show_technology_links is true" do
        component = build_component(skill_matrix: matrix_with_data, bus_factor: bus_factor_with_data, show_technology_links: true)
        render_inline(component)
        expect(page).to have_link("Ruby", href: /\/teams\/#{team.id}\/technologies\/#{technology1.id}/)
        expect(page).to have_link("React", href: /\/teams\/#{team.id}\/technologies\/#{technology2.id}/)
      end

      it "renders technology names as plain text when show_technology_links is false" do
        component = build_component(skill_matrix: matrix_with_data, bus_factor: bus_factor_with_data, show_technology_links: false)
        render_inline(component)
        expect(page).to have_text("Ruby")
        expect(page).to have_text("React")
        expect(page).not_to have_link("Ruby")
        expect(page).not_to have_link("React")
      end

      it "renders progress bar for coverage" do
        component = build_component(skill_matrix: matrix_with_data, bus_factor: bus_factor_with_data)
        render_inline(component)
        expect(page).to have_selector(".progress-bar")
        expect(page).to have_selector(".progress-bar__fill")
      end
    end

    context "when there are no changes from previous quarter" do
      it "does not render change indicators" do
        matrix = {technology1.id => {user1.id => 2, user2.id => 0}}
        component = build_component(skill_matrix: matrix)
        render_inline(component)
        expect(page).not_to have_selector(".change-indicator")
      end
    end

    context "when technology has criticality badges" do
      let(:matrix_with_data) do
        {
          technology1.id => {user1.id => 2, user2.id => 0},
          technology2.id => {user1.id => 1, user2.id => 0},
          technology3.id => {user1.id => 1, user2.id => 0}
        }
      end

      it "renders criticality badges" do
        component = build_component(skill_matrix: matrix_with_data)
        render_inline(component)
        expect(page).to have_text("High")
        expect(page).to have_text("Norm")
        expect(page).to have_text("Low")
      end
    end

    context "when technology has bus factor risk levels" do
      let(:matrix_with_data) do
        {technology1.id => {user1.id => 2, user2.id => 0}}
      end
      let(:bus_factor_medium) do
        {
          technology1.id => {count: 1, target: 2, risk_level: "medium", criticality: "high"},
          technology2.id => {count: 0, target: 2, risk_level: "high", criticality: "normal"},
          technology3.id => {count: 0, target: 1, risk_level: "high", criticality: "low"}
        }
      end

      it "renders medium risk level" do
        component = build_component(skill_matrix: matrix_with_data, bus_factor: bus_factor_medium)
        render_inline(component)
        expect(page).to have_text("1/2")
      end
    end

    context "coverage color thresholds" do
      let(:matrix_with_data) do
        {technology1.id => {user1.id => 2, user2.id => 0}}
      end
      let(:bus_factor_medium) do
        {
          technology1.id => {count: 1, target: 2, risk_level: "medium", criticality: "high"},
          technology2.id => {count: 0, target: 2, risk_level: "high", criticality: "normal"},
          technology3.id => {count: 0, target: 1, risk_level: "high", criticality: "low"}
        }
      end

      it "renders danger class for low coverage" do
        component = build_component(skill_matrix: matrix_with_data, bus_factor: bus_factor_medium)
        render_inline(component)
        expect(page).to have_selector(".progress-bar__fill--warning")
      end
    end
  end
end
