require "rails_helper"

RSpec.describe ApiClient::AssessmentPeriodPolicy, type: :policy do
  it "allows an enabled client with teams:read regardless of team scope" do
    client = build(:api_client, permissions: ["teams:read"], team_ids: [])
    expect(described_class.new(client, AssessmentPeriod).index?).to be true
  end

  [[], ["units:read"]].each do |permissions|
    it "denies permissions #{permissions.inspect}" do
      client = build(:api_client, permissions: permissions)
      expect(described_class.new(client, AssessmentPeriod).index?).to be false
    end
  end

  it "denies a disabled client with teams:read" do
    client = build(:api_client, :disabled)
    expect(described_class.new(client, AssessmentPeriod).index?).to be false
  end
end
