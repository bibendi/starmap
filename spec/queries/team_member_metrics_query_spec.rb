# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamMemberMetricsQuery do
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

  describe "#metrics" do
    context "with skill ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 3, team: team)
        create(:skill_rating, user: user1, technology: technology2, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology3, quarter: current_quarter, rating: 1, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "calculates competence level totals" do
        metrics = described_class.new(team: team, user_ids: [user1.id, user2.id], quarter: current_quarter).metrics
        expect(metrics[user1.id][:competence_level][:total]).to eq(6)
        expect(metrics[user1.id][:competence_level][:high]).to eq(3)
        expect(metrics[user1.id][:competence_level][:normal]).to eq(2)
        expect(metrics[user1.id][:competence_level][:low]).to eq(1)
      end

      it "calculates universality counts" do
        metrics = described_class.new(team: team, user_ids: [user1.id, user2.id], quarter: current_quarter).metrics
        expect(metrics[user1.id][:universality][:total]).to eq(2)
        expect(metrics[user1.id][:universality][:high]).to eq(1)
        expect(metrics[user1.id][:universality][:normal]).to eq(1)
        expect(metrics[user1.id][:universality][:low]).to eq(0)
      end

      it "calculates expertise concentration for unique experts" do
        metrics = described_class.new(team: team, user_ids: [user1.id, user2.id], quarter: current_quarter).metrics
        expect(metrics[user2.id][:expertise_concentration][:total]).to eq(0)
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
        metrics = described_class.new(team: team, user_ids: [user1.id], quarter: current_quarter).metrics
        expect(metrics[user1.id][:competence_level][:total_change]).to eq(2)
        expect(metrics[user1.id][:competence_level][:high_change]).to eq(1)
        expect(metrics[user1.id][:competence_level][:normal_change]).to eq(1)
        expect(metrics[user1.id][:universality][:total_change]).to eq(1)
      end
    end

    context "with empty user ids" do
      it "returns empty hash" do
        metrics = described_class.new(team: team, user_ids: [], quarter: current_quarter).metrics
        expect(metrics).to be_empty
      end
    end

    context "without current quarter" do
      it "returns empty hash" do
        metrics = described_class.new(team: team, user_ids: [user1.id], quarter: nil).metrics
        expect(metrics).to be_empty
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

    specify "#metrics performs constant number of queries" do
      user_ids = team.user_ids
      expect { described_class.new(team: team, user_ids: user_ids, quarter: current_quarter).metrics }.to perform_constant_number_of_queries
    end
  end
end
