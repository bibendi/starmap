require "rails_helper"

RSpec.describe ApiClient, type: :model do
  describe "validations" do
    it "requires name" do
      client = build(:api_client, name: nil)
      expect(client).not_to be_valid
      expect(client.errors[:name]).to be_present
    end

    it "requires oidc_client_id" do
      client = build(:api_client, oidc_client_id: nil)
      expect(client).not_to be_valid
      expect(client.errors[:oidc_client_id]).to be_present
    end

    it "requires unique oidc_client_id" do
      existing = create(:api_client, team_list: [create(:team)])
      client = build(:api_client, oidc_client_id: existing.oidc_client_id)
      expect(client).not_to be_valid
      expect(client.errors[:oidc_client_id]).to be_present
    end

    it "requires team_ids when any read permission is granted" do
      client = build(:api_client, permissions: ["teams:read"], team_ids: [])
      expect(client).not_to be_valid
      expect(client.errors[:team_ids]).to be_present
    end

    it "does not require team_ids when no permissions" do
      client = build(:api_client, permissions: [], team_ids: [])
      expect(client).to be_valid
    end
  end

  describe "#has_permission?" do
    let(:client) { build(:api_client, permissions: ["units:read"]) }

    it "returns true for granted permission" do
      expect(client.has_permission?("units:read")).to be true
    end

    it "returns false for missing permission" do
      expect(client.has_permission?("teams:read")).to be false
    end
  end

  describe "#can_access_team?" do
    let(:team) { create(:team) }
    let(:client) { build(:api_client, team_ids: [team.id]) }

    it "returns true for team in team_ids" do
      expect(client.can_access_team?(team)).to be true
    end

    it "returns false for team not in team_ids" do
      other = create(:team)
      expect(client.can_access_team?(other)).to be false
    end
  end
end
