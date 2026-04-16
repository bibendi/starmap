# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamSkillMatrixComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active, is_current: true) }
  let_it_be(:previous_quarter) { create(:quarter, :previous, :closed, relative_to: current_quarter) }

  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology, name: "Ruby", category_name: "Backend") }
  let_it_be(:technology2) { create(:technology, name: "React", category_name: "Frontend") }
  let_it_be(:technology3) { create(:technology, name: "PostgreSQL", category_name: "Database") }

  before do
    create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: :high)
    create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: :normal)
    create(:team_technology, team: team, technology: technology3, target_experts: 1, criticality: :low)
  end

  describe "#initialize" do
    it "initializes with a team" do
      component = described_class.new(team: team)
      expect(component.team).to eq(team)
    end

    it "sets team_members" do
      component = described_class.new(team: team)
      expect(component.team_members).to include(user1, user2)
    end

    it "sets technologies" do
      component = described_class.new(team: team)
      expect(component.technologies).to include(technology1, technology2, technology3)
    end
  end

  describe "#any_data?" do
    context "when team has no members" do
      let(:empty_team) { create(:team) }

      it "returns false" do
        component = described_class.new(team: empty_team)
        expect(component.any_data?).to be false
      end
    end

    context "when team has members but no skill ratings" do
      it "returns false" do
        component = described_class.new(team: team)
        expect(component.any_data?).to be false
      end
    end

    context "when team has members and skill ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns true" do
        component = described_class.new(team: team)
        expect(component.any_data?).to be true
      end
    end
  end

  describe "#bus_factor_for" do
    context "when technology has no experts" do
      it "returns high risk level" do
        component = described_class.new(team: team)
        bus_factor = component.bus_factor_for(technology1.id)
        expect(bus_factor[:risk_level]).to eq("high")
        expect(bus_factor[:count]).to eq(0)
      end
    end

    context "when technology has insufficient experts" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns medium risk level" do
        component = described_class.new(team: team)
        bus_factor = component.bus_factor_for(technology1.id)
        expect(bus_factor[:risk_level]).to eq("medium")
        expect(bus_factor[:count]).to eq(1)
      end
    end

    context "when technology has sufficient experts" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns low risk level" do
        component = described_class.new(team: team)
        bus_factor = component.bus_factor_for(technology1.id)
        expect(bus_factor[:risk_level]).to eq("low")
        expect(bus_factor[:count]).to eq(2)
      end
    end

    context "when there is a change from previous quarter" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns the change in expert count" do
        component = described_class.new(team: team)
        bus_factor = component.bus_factor_for(technology1.id)
        expect(bus_factor[:change]).to eq(1)
      end
    end
  end

  describe "#coverage_for" do
    context "when no experts" do
      it "returns 0" do
        component = described_class.new(team: team)
        expect(component.coverage_for(technology1.id)).to eq(0)
      end
    end

    context "when partial coverage" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns 50" do
        component = described_class.new(team: team)
        expect(component.coverage_for(technology1.id)).to eq(50)
      end
    end

    context "when full coverage" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 100" do
        component = described_class.new(team: team)
        expect(component.coverage_for(technology1.id)).to eq(100)
      end
    end

    context "when exceeding target" do
      before do
        create(:skill_rating, user: user1, technology: technology3, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology3, quarter: current_quarter, rating: 3, team: team)
      end

      it "caps at 100" do
        component = described_class.new(team: team)
        expect(component.coverage_for(technology3.id)).to eq(100)
      end
    end
  end

  describe "rendering" do
    context "when there is no data" do
      it "renders empty state message" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("No team skill data")
      end
    end

    context "when there is data" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 1, team: team)
      end

      it "renders the table header" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Competency")
        expect(page).to have_text("Bus Factor")
        expect(page).to have_text("Coverage")
      end

      it "does not render member name columns" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).not_to have_text(user1.full_name.split.first)
      end

      it "renders technology names as links when show_technology_links is true" do
        component = described_class.new(team: team, show_technology_links: true)
        render_inline(component)
        expect(page).to have_link("Ruby", href: /\/teams\/#{team.id}\/technologies\/#{technology1.id}/)
        expect(page).to have_link("React", href: /\/teams\/#{team.id}\/technologies\/#{technology2.id}/)
      end

      it "renders technology names as plain text when show_technology_links is false" do
        component = described_class.new(team: team, show_technology_links: false)
        render_inline(component)
        expect(page).to have_text("Ruby")
        expect(page).to have_text("React")
        expect(page).not_to have_link("Ruby")
        expect(page).not_to have_link("React")
      end

      it "renders progress bar for coverage" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_selector(".progress-bar")
        expect(page).to have_selector(".progress-bar__fill")
      end
    end

    context "when there are no changes from previous quarter" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "does not render change indicators" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).not_to have_selector(".change-indicator")
      end
    end

    context "when technology has criticality badges" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "renders high criticality badge" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("High")
      end

      it "renders normal criticality badge" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Norm")
      end

      it "renders low criticality badge" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Low")
      end
    end

    context "when technology has bus factor risk levels" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "renders medium risk level" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("1/2")
      end
    end

    context "coverage color thresholds" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "renders danger class for low coverage" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_selector(".progress-bar__fill--warning")
      end
    end
  end

  describe "N+1 queries", :n_plus_one do
    let_it_be(:technologies) { create_list(:technology, 3) }

    before do
      technologies.each do |tech|
        create(:team_technology, team: team, technology: tech, criticality: [:high, :normal, :low].sample)
      end
    end

    populate do |n|
      ActiveRecord::Base.connection.clear_query_cache
      team.reload
      team.users.reset

      users = create_list(:user, n, team: team)

      users.each do |user|
        technologies.each do |tech|
          create(:skill_rating,
            user: user,
            technology: tech,
            quarter: current_quarter,
            rating: rand(1..3),
            team: team)
        end
      end
    end

    specify do
      expect { render_inline(described_class.new(team: team)) }.to perform_constant_number_of_queries
    end
  end
end
