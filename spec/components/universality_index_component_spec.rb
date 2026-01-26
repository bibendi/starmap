# frozen_string_literal: true

require "rails_helper"

RSpec.describe UniversalityIndexComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology) }
  let_it_be(:technology2) { create(:technology) }
  let_it_be(:technology3) { create(:technology) }

  describe "#calculate" do
    context "when users have expert ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user2, technology: technology3, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns count of technologies per user" do
        component = described_class.new(team: team)
        expect(component.instance_variable_get(:@universality_index)).to eq(
          user1.id => 2,
          user2.id => 1
        )
      end
    end

    context "when user has no expert ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 1, team: team)
      end

      it "returns empty hash" do
        component = described_class.new(team: team)
        expect(component.instance_variable_get(:@universality_index)).to eq({})
      end
    end

    context "when no ratings exist" do
      it "returns empty hash" do
        component = described_class.new(team: team)
        expect(component.instance_variable_get(:@universality_index)).to eq({})
      end
    end

    context "when there is no current quarter" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        Quarter.destroy_all
      end

      it "returns empty hash" do
        component = described_class.new(team: team)
        expect(component.instance_variable_get(:@universality_index)).to eq({})
      end
    end

    context "when rating is below expert level" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 0, team: team)
      end

      it "does not count non-expert ratings" do
        component = described_class.new(team: team)
        expect(component.instance_variable_get(:@universality_index)).to eq({})
      end
    end
  end

  describe "rendering" do
    context "with expert ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 3, team: team)
      end

      it "displays user name and technology count" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text(user1.full_name)
        expect(page).to have_text("2 technologies")
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
