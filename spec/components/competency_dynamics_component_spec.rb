# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompetencyDynamicsComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active, is_current: true) }
  let_it_be(:previous_quarter) { create(:quarter, :previous, :closed, relative_to: current_quarter) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }

  before do
    create(:team_technology, team: team, technology: technology1, target_experts: 2)
    create(:team_technology, team: team, technology: technology2, target_experts: 2)
  end

  describe "#calculate" do
    context "when users improved their skills" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: previous_quarter, rating: 0, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 1, team: team)
      end

      it "returns positive dynamics for user1" do
        component = described_class.new(team: team)
        expect(component.competency_dynamics[user1.id]).to eq(3)
      end

      it "returns positive dynamics for user2" do
        component = described_class.new(team: team)
        expect(component.competency_dynamics[user2.id]).to eq(1)
      end
    end

    context "when users skills decreased" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 0, team: team)
      end

      it "returns negative dynamics" do
        component = described_class.new(team: team)
        expect(component.competency_dynamics[user1.id]).to eq(-4)
      end
    end

    context "when users skills did not change" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 1, team: team)
      end

      it "returns zero dynamics" do
        component = described_class.new(team: team)
        expect(component.competency_dynamics[user1.id]).to eq(0)
      end
    end

    context "when user has new technologies" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "calculates change including new technologies" do
        component = described_class.new(team: team)
        expect(component.competency_dynamics[user1.id]).to eq(4)
      end
    end

    context "when there is no previous quarter" do
      before do
        Quarter.delete_all
      end

      it "returns empty hash" do
        component = described_class.new(team: team)
        expect(component.competency_dynamics).to eq({})
      end
    end

    context "when team has no users" do
      let(:empty_team) { create(:team) }

      it "returns empty hash" do
        component = described_class.new(team: empty_team)
        expect(component.competency_dynamics).to eq({})
      end
    end
  end

  describe "rendering" do
    context "with positive dynamics" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "displays user name" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text(user1.full_name)
      end

      it "displays positive change with green badge" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("+2")
        expect(page).to have_css(".bg-green-100.text-green-800")
      end
    end

    context "with negative dynamics" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 1, team: team)
      end

      it "displays negative change with red badge" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("-2")
        expect(page).to have_css(".bg-red-100.text-red-800")
      end
    end

    context "when no dynamics data" do
      before do
        Quarter.delete_all
      end

      it "displays empty state message" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("No competency dynamics data")
      end
    end

    context "when zero dynamics" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "displays zero change" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("0")
      end
    end

    context "title and description" do
      it "displays correct title" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Competency Dynamics")
      end

      it "displays correct description" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Skill changes compared to previous quarter")
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
          # Создаём рейтинги для текущего и предыдущего кварталов
          create(:skill_rating,
                 user: user,
                 technology: tech,
                 quarter: previous_quarter,
                 rating: rand(0..3),
                 team: team)
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
