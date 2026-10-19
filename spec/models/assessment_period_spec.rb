require "rails_helper"

RSpec.describe AssessmentPeriod, type: :model do
  include ActiveSupport::Testing::TimeHelpers

  let_it_be(:earlier) { create(:assessment_period, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 3, 31)) }

  {
    "monthly" => [2028, 2, Date.new(2028, 2, 1), Date.new(2028, 2, 29), "2028-02"],
    "quarterly" => [2027, 2, Date.new(2027, 4, 1), Date.new(2027, 6, 30), "2027 Q2"],
    "semiannual" => [2027, 2, Date.new(2027, 7, 1), Date.new(2027, 12, 31), "2027 H2"],
    "annual" => [2027, 1, Date.new(2027, 1, 1), Date.new(2027, 12, 31), "2027"]
  }.each do |kind, (year, number, start_date, end_date, label)|
    it "computes #{kind} calendar dates and name" do
      period = described_class.new(period_kind: kind, calendar_year: year, calendar_number: number,
        evaluation_start_date: end_date, evaluation_end_date: end_date + 14.days)
      expect(period).to be_valid
      expect([period.start_date, period.end_date, period.full_name]).to eq([start_date, end_date, label])
    end
  end

  it "supports a custom interval across a year" do
    period = build(:assessment_period, period_kind: :custom, start_date: Date.new(2026, 11, 15), end_date: Date.new(2027, 2, 20))
    expect(period).to be_valid
    expect(period.full_name).to eq("2026-11-15 – 2027-02-20")
  end

  it "preserves an existing name and accepts evaluation starting on the last measured day" do
    expect(earlier).to be_valid
    earlier.update!(name: "Original")
    expect(earlier.reload.full_name).to eq("Original")
  end

  it "rejects overlapping inclusive boundaries, including archived periods" do
    period = build(:assessment_period, :archived, period_kind: :custom, start_date: earlier.end_date, end_date: earlier.end_date + 5.days)
    expect(period).not_to be_valid
    expect(period.errors.of_kind?(:base, :overlap)).to be true
  end

  it "accepts adjacent dates and finds the preceding snapshot across a frequency change" do
    period = create(:assessment_period, period_kind: :monthly, start_date: Date.new(2026, 4, 1), end_date: Date.new(2026, 4, 30))
    expect(period.previous_assessment_period).to eq(earlier)
    expect(earlier.previous_assessment_period).to be_nil
    expect(period).to be_valid
    expect(described_class.ordered).to eq([earlier, period])
  end

  it "allows gaps and does not filter the predecessor by status" do
    earlier.update!(status: :draft)
    period = create(:assessment_period, period_kind: :monthly, start_date: Date.new(2026, 5, 1), end_date: Date.new(2026, 5, 31))
    expect(period.previous_assessment_period).to eq(earlier)
  end

  it "rejects noncalendar boundaries for standard types" do
    period = build(:assessment_period, start_date: Date.new(2027, 4, 15), end_date: Date.new(2027, 6, 30))
    expect(period).not_to be_valid
    expect(period.errors.of_kind?(:start_date, :invalid_calendar)).to be true
  end

  it "rejects invalid calendar numbers without raising" do
    period = described_class.new(period_kind: :semiannual, calendar_year: "2027", calendar_number: "3")
    expect(period).not_to be_valid
    expect(period.errors.of_kind?(:start_date, :invalid_calendar)).to be true
  end

  it "rejects reversed measured and evaluation dates" do
    period = build(:assessment_period, period_kind: :custom, start_date: Date.new(2027, 4, 15), end_date: Date.new(2027, 4, 15))
    period.evaluation_start_date = period.end_date - 1.day
    period.evaluation_end_date = period.evaluation_start_date
    expect(period).not_to be_valid
    expect(period.errors.attribute_names).to include(:end_date, :evaluation_start_date, :evaluation_end_date)
  end

  it "includes both evaluation window endpoints" do
    travel_to earlier.evaluation_start_date do
      expect(earlier.evaluation_period?).to be true
    end
    travel_to earlier.evaluation_end_date do
      expect(earlier.evaluation_period?).to be true
    end
    travel_to earlier.evaluation_end_date + 1.day do
      expect(earlier.evaluation_period?).to be false
    end
  end

  it "keeps the current selection on closing" do
    earlier.update!(status: :active)
    earlier.update!(status: :closed)
    expect(described_class.current).to eq(earlier)
  end
end
