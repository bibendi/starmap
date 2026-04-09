require "rails_helper"

RSpec.describe Quarter, type: :model do
  describe "validations" do
    it "auto-sets name via callback so nil name passes on create" do
      quarter = build(:quarter, name: nil)

      expect(quarter).to be_valid
    end

    it "requires unique name scoped to year" do
      create(:quarter, name: "Alpha", year: 2026)
      duplicate = build(:quarter, name: "Alpha", year: 2026)
      duplicate.valid?

      expect(duplicate.errors[:name]).to include(I18n.t("errors.messages.taken"))
    end

    it "allows same name in different year" do
      create(:quarter, name: "Alpha", year: 2026)
      other = build(:quarter, name: "Alpha", year: 2027)
      other.valid?

      expect(other.errors[:name]).to be_empty
    end

    it "requires year" do
      quarter = described_class.new(year: nil)
      quarter.valid?

      expect(quarter.errors[:year]).to include(I18n.t("errors.messages.blank"))
    end

    it "requires year > 2000" do
      quarter = described_class.new(year: 1999)
      quarter.valid?

      expect(quarter.errors[:year]).to be_present
    end

    it "requires quarter_number in [1,2,3,4]" do
      quarter = described_class.new(quarter_number: 5)
      quarter.valid?

      expect(quarter.errors[:quarter_number]).to be_present
    end

    it "requires unique quarter_number scoped to year" do
      existing = create(:quarter, year: 2026, quarter_number: 1)
      duplicate = build(:quarter, year: 2026, quarter_number: 1,
        name: "Other", start_date: existing.start_date, end_date: existing.end_date,
        evaluation_start_date: existing.evaluation_start_date, evaluation_end_date: existing.evaluation_end_date)
      duplicate.valid?

      expect(duplicate.errors[:quarter_number]).to include(
        I18n.t("activerecord.errors.models.quarter.attributes.quarter_number.taken")
      )
    end

    it "requires start_date" do
      quarter = described_class.new(start_date: nil)
      quarter.valid?

      expect(quarter.errors[:start_date]).to include(I18n.t("errors.messages.blank"))
    end

    it "requires end_date" do
      quarter = described_class.new(end_date: nil)
      quarter.valid?

      expect(quarter.errors[:end_date]).to include(I18n.t("errors.messages.blank"))
    end

    it "validates end_date after start_date" do
      quarter = build(:quarter, start_date: Date.new(2026, 6, 1), end_date: Date.new(2026, 5, 1))
      quarter.valid?

      expect(quarter.errors[:end_date]).to be_present
    end

    it "validates evaluation_start_date within quarter period" do
      quarter = build(:quarter,
        start_date: Date.new(2026, 4, 1), end_date: Date.new(2026, 6, 30),
        evaluation_start_date: Date.new(2026, 3, 1), evaluation_end_date: Date.new(2026, 4, 15))
      quarter.valid?

      expect(quarter.errors[:evaluation_start_date]).to be_present
    end

    it "validates evaluation_end_date after evaluation_start_date" do
      quarter = build(:quarter,
        start_date: Date.new(2026, 4, 1), end_date: Date.new(2026, 6, 30),
        evaluation_start_date: Date.new(2026, 4, 15), evaluation_end_date: Date.new(2026, 4, 10))
      quarter.valid?

      expect(quarter.errors[:evaluation_end_date]).to be_present
    end

    it "rejects past year" do
      quarter = build(:quarter, year: 2020)
      quarter.valid?

      expect(quarter.errors[:year]).to be_present
    end

    it "accepts current year" do
      quarter = build(:quarter, year: Date.current.year)
      quarter.valid?

      expect(quarter.errors[:year]).to be_empty
    end
  end

  describe "callbacks" do
    describe "before_validation :set_quarter_name, on: :create" do
      it "auto-sets name from year and quarter_number" do
        quarter = create(:quarter, name: nil, year: 2026, quarter_number: 2)

        expect(quarter.reload.name).to eq("2026 Q2")
      end

      it "does not overwrite explicit name" do
        quarter = create(:quarter, name: "Custom Name")

        expect(quarter.reload.name).to eq("Custom Name")
      end
    end

    describe "after_create :set_as_current_if_first" do
      it "sets is_current when it is the first quarter" do
        quarter = create(:quarter)

        expect(quarter.reload.is_current).to be true
      end

      it "does not set is_current when other quarters exist" do
        create(:quarter)
        second = create(:quarter)

        expect(second.reload.is_current).to be false
      end
    end

    describe "after_update :handle_status_change" do
      let_it_be(:quarter) { create(:quarter, :draft) }
      let_it_be(:user) { create(:engineer) }
      let_it_be(:technology) { create(:technology) }

      before do
        create(:skill_rating, user: user, technology: technology, quarter: quarter, status: "draft")
      end

      it "approves draft ratings when quarter is closed" do
        quarter.update!(status: "active")
        quarter.update!(status: "closed")

        expect(SkillRating.where(quarter: quarter).pluck(:status)).to all(eq("approved"))
      end

      it "does not change ratings when status has not changed" do
        quarter.update!(description: "updated")

        expect(quarter.skill_ratings.pluck(:status)).to all(eq("draft"))
      end
    end
  end

  describe "#full_name" do
    it "returns formatted year and quarter number" do
      quarter = build(:quarter, year: 2026, quarter_number: 3)

      expect(quarter.full_name).to eq("2026 Q3")
    end
  end

  describe "#evaluation_period?" do
    it "returns true when today is within evaluation period" do
      quarter = build(:quarter,
        evaluation_start_date: Date.current - 5.days,
        evaluation_end_date: Date.current + 5.days)

      expect(quarter.evaluation_period?).to be true
    end

    it "returns false when today is before evaluation period" do
      quarter = build(:quarter,
        evaluation_start_date: Date.current + 10.days,
        evaluation_end_date: Date.current + 20.days)

      expect(quarter.evaluation_period?).to be false
    end

    it "returns false when today is after evaluation period" do
      quarter = build(:quarter,
        evaluation_start_date: Date.current - 20.days,
        evaluation_end_date: Date.current - 10.days)

      expect(quarter.evaluation_period?).to be false
    end
  end

  describe "#previous_quarter" do
    it "returns the chronologically previous quarter" do
      q1 = create(:quarter, year: 2026, quarter_number: 1)
      q2 = create(:quarter, year: 2026, quarter_number: 2)

      expect(q2.previous_quarter).to eq(q1)
    end

    it "returns nil when no previous quarter exists" do
      quarter = create(:quarter)

      expect(quarter.previous_quarter).to be_nil
    end

    it "crosses year boundary" do
      q4 = create(:quarter, year: 2026, quarter_number: 4)
      q1_next_year = create(:quarter, year: 2027, quarter_number: 1)

      expect(q1_next_year.previous_quarter).to eq(q4)
    end
  end

  describe ".current" do
    it "returns the quarter with is_current true" do
      current = create(:quarter, :current)

      expect(described_class.current).to eq(current)
    end

    it "returns nil when no current quarter" do
      expect(described_class.current).to be_nil
    end
  end

  describe ".ordered" do
    it "orders by year and quarter_number" do
      q3 = create(:quarter, year: 2026, quarter_number: 3)
      q1 = create(:quarter, year: 2026, quarter_number: 1)
      q2 = create(:quarter, year: 2026, quarter_number: 2)

      expect(described_class.ordered.to_a).to eq([q1, q2, q3])
    end
  end

  describe "associations" do
    it "destroys skill_ratings on destroy" do
      quarter = create(:quarter)
      create(:skill_rating, quarter: quarter)

      expect { quarter.destroy }.to change(SkillRating, :count).by(-1)
    end

    it "destroys action_plans on destroy" do
      quarter = create(:quarter)
      create(:action_plan, quarter: quarter)

      expect { quarter.destroy }.to change(ActionPlan, :count).by(-1)
    end
  end
end
