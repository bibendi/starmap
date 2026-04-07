require "rails_helper"

RSpec.describe Team, type: :model do
  describe "associations" do
    it "belongs to unit" do
      unit = build(:unit)
      team = build(:team, unit: unit)

      expect(team.unit).to eq(unit)
    end

    it "belongs to team_lead" do
      user = build(:team_lead, team: nil)
      team = build(:team, unit: build(:unit), team_lead: user)

      expect(team.team_lead).to eq(user)
    end

    it "allows nil team_lead" do
      team = build(:team, team_lead: nil, unit: build(:unit))

      expect(team.team_lead).to be_nil
    end

    it "has many users" do
      team = create(:team)
      user = create(:engineer, team: team)

      expect(team.users).to include(user)
    end

    it "has many team_technologies" do
      team = create(:team)
      technology = create(:technology)
      team_technology = create(:team_technology, team: team, technology: technology)

      expect(team.team_technologies).to include(team_technology)
    end
  end

  describe "validations" do
    it "requires name" do
      team = described_class.new(name: nil)
      team.valid?

      expect(team.errors[:name]).to include(I18n.t("errors.messages.blank"))
    end

    it "requires unique name" do
      create(:team, name: "Alpha")
      team = described_class.new(name: "Alpha")
      team.valid?

      expect(team.errors[:name]).to include(I18n.t("errors.messages.taken"))
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active teams" do
        active_team = create(:team, name: "Active Team", active: true)
        inactive_team = create(:team, name: "Inactive Team", active: false)

        expect(described_class.active).to include(active_team)
        expect(described_class.active).not_to include(inactive_team)
      end
    end

    describe ".by_unit" do
      it "returns teams for a specific unit" do
        unit_a = create(:unit, name: "Unit A")
        unit_b = create(:unit, name: "Unit B")
        team_a = create(:team, name: "Team A", unit: unit_a)
        create(:team, name: "Team B", unit: unit_b)

        expect(described_class.by_unit(unit_a)).to include(team_a)
        expect(described_class.by_unit(unit_a)).not_to include(described_class.find_by(name: "Team B"))
      end
    end

    describe ".ordered" do
      it "orders teams by name" do
        team_c = create(:team, name: "Charlie")
        team_a = create(:team, name: "Alpha")
        team_b = create(:team, name: "Bravo")

        expect(described_class.ordered.to_a).to eq([team_a, team_b, team_c])
      end
    end
  end

  describe "delegation" do
    it "delegates name to unit" do
      unit = build(:unit, name: "Engineering")
      team = build(:team, unit: unit)

      expect(team.unit_name).to eq("Engineering")
    end
  end

  describe "#has_team_lead?" do
    it "returns true when team_lead is set" do
      team = create(:team, :with_team_lead)
      expect(team.has_team_lead?).to be true
    end

    it "returns false when team_lead is nil" do
      team = build(:team, team_lead: nil, unit: build(:unit))
      expect(team.has_team_lead?).to be false
    end
  end

  describe "destroy" do
    it "cannot destroy team with associated users" do
      team = create(:team)
      create(:engineer, team: team)

      expect { team.destroy }.not_to change(described_class, :count)
      expect(team.errors[:base]).to be_present
    end

    it "destroys team without associated users" do
      team = create(:team)

      expect { team.destroy }.to change(described_class, :count).by(-1)
    end

    it "destroys associated team_technologies" do
      team = create(:team)
      technology = create(:technology)
      create(:team_technology, team: team, technology: technology)

      expect { team.destroy }.to change(TeamTechnology, :count).by(-1)
    end
  end
end
