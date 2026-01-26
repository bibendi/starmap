# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamMemberMetricsComponent, type: :component do
  let_it_be(:current_quarter) { create(:quarter, status: :active, is_current: true) }
  let_it_be(:previous_quarter) { create(:quarter, :previous, :closed, relative_to: current_quarter) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology, criticality: :high) }
  let_it_be(:technology2) { create(:technology, criticality: :normal) }
  let_it_be(:technology3) { create(:technology, criticality: :low) }

  before do
    create(:team_technology, team: team, technology: technology1, criticality: :high)
    create(:team_technology, team: team, technology: technology2, criticality: :normal)
    create(:team_technology, team: team, technology: technology3, criticality: :low)
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

  describe "team_member_metrics calculation" do
    context "with skill ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology3, quarter: current_quarter, rating: 1, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "calculates competence level totals" do
        component = described_class.new(team: team)
        metrics = component.team_member_metrics[user1.id]
        expect(metrics[:competence_level][:total]).to eq(6)
        expect(metrics[:competence_level][:high]).to eq(3)
        expect(metrics[:competence_level][:normal]).to eq(2)
        expect(metrics[:competence_level][:low]).to eq(1)
      end

      it "calculates universality counts" do
        component = described_class.new(team: team)
        metrics = component.team_member_metrics[user1.id]
        expect(metrics[:universality][:total]).to eq(2)
        expect(metrics[:universality][:high]).to eq(1)
        expect(metrics[:universality][:normal]).to eq(1)
        expect(metrics[:universality][:low]).to eq(0)
      end

      it "calculates expertise concentration for unique experts" do
        component = described_class.new(team: team)
        metrics = component.team_member_metrics[user2.id]
        expect(metrics[:expertise_concentration][:total]).to eq(0)
      end
    end

    context "with previous quarter data" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 2, team: team)
      end

      it "calculates changes in metrics" do
        component = described_class.new(team: team)
        metrics = component.team_member_metrics[user1.id]
        expect(metrics[:competence_level][:total_change]).to eq(2)
        expect(metrics[:competence_level][:high_change]).to eq(1)
        expect(metrics[:competence_level][:normal_change]).to eq(1)
        expect(metrics[:universality][:total_change]).to eq(1)
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
      # Clear ActiveRecord query cache between iterations
      ActiveRecord::Base.connection.clear_query_cache
      # Reset team association to ensure users are loaded fresh
      team.reload
      team.users.reset

      # Create n users for the team
      users = create_list(:user, n, team: team)

      # Create skill ratings for each user for each technology
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
      expect { described_class.new(team: team).team_member_metrics }.to perform_constant_number_of_queries
    end
  end

  describe "rendering" do
    context "when there is no data" do
      it "renders empty state message" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("No team member metrics data")
      end
    end

    context "when there is data" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 1, team: team)
      end

      it "renders the table header" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Team Member Metrics")
        expect(page).to have_text("Competency level, universality and expertise concentration by technology criticality")
      end

      it "renders user first names" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text(user1.full_name.split.first)
        expect(page).to have_text(user2.full_name.split.first)
      end

      it "renders competence level section" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Competence Level")
        expect(page).to have_text("Total")
      end

      it "renders universality section" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Universality")
      end

      it "renders expertise concentration section" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("Expertise Concentration")
      end

      it "renders metric values" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("3")
        expect(page).to have_text("2")
        expect(page).to have_text("1")
      end
    end

    context "when there are changes from previous quarter" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: previous_quarter, rating: 1, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "renders change indicators" do
        component = described_class.new(team: team)
        render_inline(component)
        expect(page).to have_text("+1")
      end
    end
  end
end
