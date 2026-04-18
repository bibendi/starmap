# frozen_string_literal: true

require "rails_helper"

RSpec.describe TeamSkillMatrixQuery do
  let_it_be(:current_quarter) { create(:quarter, status: :active, is_current: true) }
  let_it_be(:previous_quarter) { create(:quarter, :previous, :closed, relative_to: current_quarter) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user1) { create(:user, team: team) }
  let_it_be(:user2) { create(:user, team: team) }
  let_it_be(:technology1) { create(:technology, name: "Ruby", category_name: "Backend") }
  let_it_be(:technology2) { create(:technology, name: "React", category_name: "Frontend") }
  let_it_be(:technology3) { create(:technology, name: "PostgreSQL", category_name: "Database") }

  let(:user_ids) { [user1.id, user2.id] }
  let(:technologies) { [technology1, technology2, technology3] }

  before do
    create(:team_technology, team: team, technology: technology1, target_experts: 2, criticality: :high)
    create(:team_technology, team: team, technology: technology2, target_experts: 2, criticality: :normal)
    create(:team_technology, team: team, technology: technology3, target_experts: 1, criticality: :low)
  end

  describe "#bus_factor" do
    context "when technology has no experts" do
      it "returns high risk level" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).bus_factor
        expect(result[technology1.id][:risk_level]).to eq("high")
        expect(result[technology1.id][:count]).to eq(0)
      end
    end

    context "when technology has insufficient experts" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns medium risk level" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).bus_factor
        expect(result[technology1.id][:risk_level]).to eq("medium")
        expect(result[technology1.id][:count]).to eq(1)
      end
    end

    context "when technology has sufficient experts" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns low risk level" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).bus_factor
        expect(result[technology1.id][:risk_level]).to eq("low")
        expect(result[technology1.id][:count]).to eq(2)
      end
    end

    context "when there is a change from previous quarter" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns the change in expert count" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).bus_factor
        expect(result[technology1.id][:change]).to eq(1)
      end
    end
  end

  describe "#raw_ratings" do
    context "with no ratings" do
      it "returns empty hash for technology" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).raw_ratings
        expect(result[technology1.id]).to be_nil
      end
    end

    context "with partial ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "returns sparse hash without defaults for unrated users" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).raw_ratings
        expect(result[technology1.id][user1.id]).to eq(2)
        expect(result[technology1.id]).not_to be_key(user2.id)
      end
    end
  end

  describe "#skill_matrix" do
    context "with no ratings" do
      it "returns zeroed matrix" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).skill_matrix
        expect(result[technology1.id][user1.id]).to eq(0)
        expect(result[technology1.id][user2.id]).to eq(0)
      end
    end

    context "with ratings" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
        create(:skill_rating, user: user2, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "returns ratings by technology and user" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).skill_matrix
        expect(result[technology1.id][user1.id]).to eq(2)
        expect(result[technology1.id][user2.id]).to eq(3)
      end
    end
  end

  describe "#rating_dynamics" do
    context "with no previous quarter" do
      it "returns empty hash" do
        allow(current_quarter).to receive(:previous_quarter).and_return(nil)
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).rating_dynamics
        expect(result).to be_empty
      end
    end

    context "with changes between quarters" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 3, team: team)
      end

      it "calculates rating differences" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).rating_dynamics
        expect(result[technology1.id][user1.id]).to eq(1)
      end
    end

    context "with no changes between quarters" do
      before do
        create(:skill_rating, user: user1, technology: technology1, quarter: previous_quarter, rating: 2, team: team)
        create(:skill_rating, user: user1, technology: technology1, quarter: current_quarter, rating: 2, team: team)
      end

      it "does not include unchanged ratings" do
        result = described_class.new(team: team, technologies: technologies, user_ids: user_ids, quarter: current_quarter).rating_dynamics
        expect(result).to be_empty
      end
    end
  end

  describe "N+1 queries", :n_plus_one do
    let_it_be(:n_plus_one_technologies) { create_list(:technology, 3) }

    before do
      n_plus_one_technologies.each do |tech|
        create(:team_technology, team: team, technology: tech, criticality: [:high, :normal, :low].sample)
      end
    end

    populate do |n|
      ActiveRecord::Base.connection.clear_query_cache
      team.reload
      team.users.reset

      users = create_list(:user, n, team: team)

      users.each do |user|
        n_plus_one_technologies.each do |tech|
          create(:skill_rating,
            user: user,
            technology: tech,
            quarter: current_quarter,
            rating: rand(1..3),
            team: team)
        end
      end
    end

    specify "#bus_factor performs constant number of queries" do
      ids = team.user_ids
      expect { described_class.new(team: team, technologies: n_plus_one_technologies, user_ids: ids, quarter: current_quarter).bus_factor }.to perform_constant_number_of_queries
    end

    specify "#skill_matrix performs constant number of queries" do
      ids = team.user_ids
      expect { described_class.new(team: team, technologies: n_plus_one_technologies, user_ids: ids, quarter: current_quarter).skill_matrix }.to perform_constant_number_of_queries
    end

    specify "#rating_dynamics performs constant number of queries" do
      ids = team.user_ids
      expect { described_class.new(team: team, technologies: n_plus_one_technologies, user_ids: ids, quarter: current_quarter).rating_dynamics }.to perform_constant_number_of_queries
    end
  end
end
