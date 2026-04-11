require "rails_helper"

RSpec.describe SkillRating, type: :model do
  let_it_be(:quarter) { create(:quarter, :current) }
  let_it_be(:team) { create(:team) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:approver) { create(:team_lead, team: team) }

  describe "#approve!" do
    it "transitions submitted to approved" do
      rating = create(:skill_rating, :submitted, user: engineer, quarter: quarter, team: team)

      rating.approve!(approver)

      expect(rating).to have_attributes(
        status: "approved",
        approved_by: approver,
        approved_at: a_value_within(1.second).of(Time.current)
      )
    end

    it "raises when not submitted" do
      rating = create(:skill_rating, :draft, user: engineer, quarter: quarter, team: team)

      expect { rating.approve!(approver) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "raises when already approved" do
      rating = create(:skill_rating, :submitted, user: engineer, quarter: quarter, team: team)
      rating.approve!(approver)

      expect { rating.approve!(approver) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end

  describe "#reject!" do
    it "transitions submitted to rejected" do
      rating = create(:skill_rating, :submitted, user: engineer, quarter: quarter, team: team)

      rating.reject!(approver)

      expect(rating).to have_attributes(
        status: "rejected",
        approved_by: approver,
        approved_at: a_value_within(1.second).of(Time.current)
      )
    end

    it "raises when not submitted" do
      rating = create(:skill_rating, :draft, user: engineer, quarter: quarter, team: team)

      expect { rating.reject!(approver) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    it "raises when already rejected" do
      rating = create(:skill_rating, :submitted, user: engineer, quarter: quarter, team: team)
      rating.reject!(approver)

      expect { rating.reject!(approver) }.to raise_error(ActiveRecord::RecordInvalid)
    end
  end
end
