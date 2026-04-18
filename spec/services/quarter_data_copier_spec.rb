require "rails_helper"

RSpec.describe QuarterDataCopier, type: :service do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:team) { create(:team) }
  let_it_be(:technology) { create(:technology) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:previous_quarter) { create(:quarter, status: :closed, is_current: false) }
  let_it_be(:new_quarter) { create(:quarter, status: :draft, is_current: false) }

  describe "#copy_from_previous" do
    context "when there is a previous quarter" do
      before do
        create(:skill_rating,
          user: user,
          team: team,
          technology: technology,
          quarter: previous_quarter,
          rating: 2,
          status: :approved,
          approved_by: admin,
          approved_at: Time.current)
      end

      it "copies skill ratings to new quarter" do
        copier = described_class.new(new_quarter, previous_quarter)
        result = copier.copy_from_previous

        expect(result).to be true
        expect(new_quarter.skill_ratings.count).to eq(1)

        new_rating = new_quarter.skill_ratings.first
        expect(new_rating.user).to eq(user)
        expect(new_rating.technology).to eq(technology)
        expect(new_rating.team).to eq(team)
        expect(new_rating.rating).to eq 2
        expect(new_rating.status).to eq "draft"
      end
    end

    context "when user is no longer a member of the team" do
      before do
        user.update!(team: nil)
        create(:skill_rating,
          user: user,
          team: team,
          technology: technology,
          quarter: previous_quarter,
          rating: 2,
          status: :approved,
          approved_by: admin,
          approved_at: Time.current)
      end

      it "skips copying ratings for users not on the team" do
        copier = described_class.new(new_quarter, previous_quarter)
        result = copier.copy_from_previous

        expect(result).to be true
        expect(new_quarter.skill_ratings.count).to eq(0)
      end
    end

    context "when user moved to another team" do
      let_it_be(:other_team) { create(:team) }

      before do
        user.update!(team: other_team)
        create(:skill_rating,
          user: user,
          team: team,
          technology: technology,
          quarter: previous_quarter,
          rating: 2,
          status: :approved,
          approved_by: admin,
          approved_at: Time.current)
      end

      it "skips copying ratings from old team" do
        copier = described_class.new(new_quarter, previous_quarter)
        result = copier.copy_from_previous

        expect(result).to be true
        expect(new_quarter.skill_ratings.count).to eq(0)
      end
    end

    context "when there is no previous quarter" do
      let(:previous_quarter) { nil }

      it "returns true without copying" do
        copier = described_class.new(new_quarter, previous_quarter)
        result = copier.copy_from_previous

        expect(result).to be true
        expect(new_quarter.skill_ratings.count).to eq(0)
      end
    end
  end
end
