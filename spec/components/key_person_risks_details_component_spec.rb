# frozen_string_literal: true

require "rails_helper"

RSpec.describe KeyPersonRisksDetailsComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team, first_name: "John", last_name: "Doe") }
  let_it_be(:user2) { create(:user, team: team, first_name: "Jane", last_name: "Smith") }
  let_it_be(:technology1) { create(:technology, name: "Ruby", category: "Backend") }
  let_it_be(:technology2) { create(:technology, name: "PostgreSQL", category: "Database") }
  let_it_be(:technology3) { create(:technology, name: "React", category: "Frontend") }

  describe "#calculate" do
    context "when technologies have single expert" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user2, technology: technology3, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns 3 key person risks" do
        component = described_class.new(team: team)
        expect(component.risks_data.size).to eq(3)
        expect(component.any_risks?).to be true
      end

      it "includes technology and user data" do
        component = described_class.new(team: team)
        tech_names = component.risks_data.map { |r| r[:technology]&.name }
        user_names = component.risks_data.map { |r| r[:user]&.full_name }

        expect(tech_names).to include("Ruby", "PostgreSQL", "React")
        expect(user_names).to include("John Doe", "Jane Smith")
      end
    end

    context "when technologies have multiple experts" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns 0 key person risks" do
        component = described_class.new(team: team)
        expect(component.risks_data).to be_empty
        expect(component.any_risks?).to be false
      end
    end

    context "when team has no technologies" do
      let(:empty_team) { create(:team) }

      it "returns empty array" do
        component = described_class.new(team: empty_team)
        expect(component.risks_data).to be_empty
        expect(component.any_risks?).to be false
      end
    end

    context "when there is no current quarter" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        Quarter.destroy_all
      end

      it "returns empty array" do
        component = described_class.new(team: team)
        expect(component.risks_data).to be_empty
        expect(component.any_risks?).to be false
      end
    end

    context "when rating is below expert level" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 1, team: team)
      end

      it "does not count non-expert ratings" do
        component = described_class.new(team: team)
        expect(component.risks_data).to be_empty
        expect(component.any_risks?).to be false
      end
    end
  end

  describe "rendering" do
    context "when there are key person risks" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "renders technology names" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Ruby")
        expect(page).to have_text("PostgreSQL")
      end

      it "renders technology categories" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Backend")
        expect(page).to have_text("Database")
      end

      it "renders user names" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("John Doe")
      end

      it "renders header" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Key Person Risks")
        expect(page).to have_text("Technologies with single expert")
      end
    end

    context "when there are no key person risks" do
      it "renders empty state message" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("No key person risks detected")
      end
    end
  end

  describe "N+1 queries", :n_plus_one do
    let_it_be(:technologies) { create_list(:technology, 3) }

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
