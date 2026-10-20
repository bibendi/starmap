require "rails_helper"

RSpec.describe AssessmentPeriodPolicy, type: :policy do
  %w[engineer team_lead unit_lead admin].each do |role|
    it "allows #{role} to read the catalogue" do
      user = build(:user, role: role)
      expect(described_class.new(user, AssessmentPeriod).index?).to be true
    end
  end

  it "denies an unauthenticated identity" do
    expect(described_class.new(nil, AssessmentPeriod).index?).to be false
  end
end
