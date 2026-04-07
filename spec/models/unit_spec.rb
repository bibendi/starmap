require "rails_helper"

RSpec.describe Unit, type: :model do
  describe "associations" do
    it "has many teams" do
      unit = create(:unit)
      team = create(:team, unit: unit)

      expect(unit.teams).to include(team)
    end

    it "belongs to unit_lead" do
      user = build(:admin, team: nil)
      unit = build(:unit, unit_lead: user)

      expect(unit.unit_lead).to eq(user)
    end

    it "allows nil unit_lead" do
      unit = build(:unit, unit_lead: nil)

      expect(unit.unit_lead).to be_nil
    end
  end

  describe "validations" do
    it "requires name" do
      unit = described_class.new(name: nil)
      unit.valid?

      expect(unit.errors[:name]).to include(I18n.t("errors.messages.blank"))
    end

    it "requires unique name" do
      create(:unit, name: "Engineering")
      unit = described_class.new(name: "Engineering")
      unit.valid?

      expect(unit.errors[:name]).to include(I18n.t("errors.messages.taken"))
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active units" do
        active_unit = create(:unit, name: "Active Unit", active: true)
        inactive_unit = create(:unit, name: "Inactive Unit", active: false)

        expect(described_class.active).to include(active_unit)
        expect(described_class.active).not_to include(inactive_unit)
      end
    end

    describe ".ordered" do
      it "orders units by name" do
        unit_c = create(:unit, name: "Charlie")
        unit_a = create(:unit, name: "Alpha")
        unit_b = create(:unit, name: "Bravo")

        expect(described_class.ordered.to_a).to eq([unit_a, unit_b, unit_c])
      end
    end
  end

  describe "#to_s" do
    it "returns the unit name" do
      unit = build(:unit, name: "Engineering")
      expect(unit.to_s).to eq("Engineering")
    end
  end

  describe "destroy" do
    it "cannot destroy unit with associated teams" do
      team = create(:team)
      unit = team.unit

      expect { unit.destroy }.not_to change(described_class, :count)
      expect(unit.errors[:base]).to be_present
    end

    it "destroys unit without associated teams" do
      unit = create(:unit)

      expect { unit.destroy }.to change(described_class, :count).by(-1)
    end
  end
end
