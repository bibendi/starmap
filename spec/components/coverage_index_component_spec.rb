# frozen_string_literal: true

require "rails_helper"

RSpec.describe CoverageIndexComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  before do
    create(:team_technology, team: team, technology: technology1, target_experts: 2)
    create(:team_technology, team: team, technology: technology2, target_experts: 2)
  end

  describe "#calculate" do
    context "when technologies have sufficient experts" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns 100% coverage" do
        component = described_class.new(team: team)
        expect(component.coverage_index).to eq(100)
      end
    end

    context "when technologies have insufficient experts" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 50% coverage" do
        component = described_class.new(team: team)
        expect(component.coverage_index).to eq(50)
      end
    end

    context "when team has no technologies" do
      let(:empty_team) { create(:team) }

      it "returns 0% coverage" do
        component = described_class.new(team: empty_team)
        expect(component.coverage_index).to eq(0)
      end
    end

    context "when custom target_experts is set" do
      before do
        team.team_technologies.find_by(technology: technology1).update(target_experts: 1)
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user, technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "calculates based on custom target" do
        component = described_class.new(team: team)
        expect(component.coverage_index).to eq(50)
      end
    end

    context "when there is no current quarter" do
      before do
        Quarter.destroy_all
      end

      it "returns 0% coverage" do
        component = described_class.new(team: team)
        expect(component.coverage_index).to eq(0)
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
        expect(page).to have_text("Coverage Index")
        expect(page).to have_text("Technology coverage indicator")
      end
    end

    context "CSS classes" do
      it "applies correct gradient and border classes" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_css(".bg-gradient-to-br.from-indigo-50.to-blue-50")
        expect(page).to have_css(".border-indigo-100")
      end
    end

    context "coverage value display" do
      before do
        create(:skill_rating, user: user, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: create(:user, team: team), technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "displays percentage" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("50%")
      end
    end
  end

  describe "N+1 queries", :n_plus_one do
    let_it_be(:technologies) { create_list(:technology, 3) }

    before do
      technologies.each do |tech|
        create(:team_technology, team: team, technology: tech, 
               criticality: [:normal, :high].sample, target_experts: 2)
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
                 rating: rand(0..3),
                 team: team)
        end
      end
    end

    specify do
      expect { render_inline(described_class.new(team: team)) }.to perform_constant_number_of_queries
    end
  end
end
