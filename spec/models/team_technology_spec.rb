require "rails_helper"

RSpec.describe TeamTechnology, type: :model do
  describe "validations" do
    it "is valid with default factory" do
      team_tech = build(:team_technology)

      expect(team_tech).to be_valid
    end

    it "requires valid criticality" do
      team_tech = build(:team_technology, criticality: "invalid")

      expect(team_tech).not_to be_valid
      expect(team_tech.errors[:criticality]).to be_present
    end

    it "requires target_experts to be a positive integer" do
      team_tech = build(:team_technology, target_experts: 0)

      expect(team_tech).not_to be_valid
      expect(team_tech.errors[:target_experts]).to be_present
    end

    it "requires unique technology per team" do
      existing = create(:team_technology)
      duplicate = build(:team_technology, team: existing.team, technology: existing.technology)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:technology_id]).to be_present
    end

    it "allows same technology in different teams" do
      technology = create(:technology)
      create(:team_technology, technology: technology)
      other = build(:team_technology, technology: technology)

      expect(other).to be_valid
    end
  end

  describe "callbacks" do
    it "sets criticality from technology when blank" do
      technology = create(:technology, criticality: "high")
      team_tech = build(:team_technology, technology: technology, criticality: nil)

      team_tech.valid?

      expect(team_tech.criticality).to eq("high")
    end

    it "sets target_experts from technology" do
      technology = create(:technology, target_experts: 5)
      team_tech = build(:team_technology, technology: technology, target_experts: nil)

      team_tech.valid?

      expect(team_tech.target_experts).to eq(5)
    end

    it "does not overwrite explicitly set values" do
      team_tech = build(:team_technology, criticality: "high", target_experts: 5)

      team_tech.valid?

      expect(team_tech.criticality).to eq("high")
      expect(team_tech.target_experts).to eq(5)
    end
  end
end
