require "rails_helper"

RSpec.describe AssessmentPeriodStatusService, type: :service do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:team) { create(:team) }
  let_it_be(:user) { create(:user, team: team) }
  let_it_be(:previous) { create(:assessment_period, :closed, start_date: Date.new(2026, 1, 1), end_date: Date.new(2026, 3, 31)) }
  let_it_be(:target) { create(:assessment_period, :draft, period_kind: :monthly, start_date: Date.new(2026, 4, 1), end_date: Date.new(2026, 4, 30)) }
  let_it_be(:technology) { create(:technology) }
  let_it_be(:other_technology) { create(:technology) }

  before do
    create(:skill_rating, user: user, team: team, technology: technology, assessment_period: previous, rating: 3, status: :approved)
    create(:skill_rating, user: user, team: team, technology: other_technology, assessment_period: previous, rating: 2, status: :approved)
  end

  it "rolls back current selection, activation and partially copied ratings on failure" do
    calls = 0
    allow(target.skill_ratings).to receive(:create!).and_wrap_original do |method, *args|
      calls += 1
      raise ActiveRecord::RecordInvalid, SkillRating.new if calls == 2

      method.call(*args)
    end
    service = described_class.new(target, admin)
    expect(service.activate).to be false
    expect(target.reload).to be_draft
    expect(target.skill_ratings.count).to eq(0)
    expect(AssessmentPeriod.current).to eq(previous)
    expect(previous.skill_ratings.count).to eq(2)
  end

  it "handles a concurrent unique selection conflict as an unsuccessful activation" do
    allow(target).to receive(:update!).and_raise(ActiveRecord::RecordNotUnique)
    service = described_class.new(target, admin)
    expect(service.activate).to be false
    expect(AssessmentPeriod.current).to eq(previous)
    expect(target.reload).to be_draft
    expect(service.errors).not_to be_empty
  end

  it "approves only draft and submitted ratings when closing and retains current" do
    expect(described_class.new(target, admin).activate).to be true
    ratings = target.skill_ratings.order(:id).to_a
    ratings.first.update!(status: :submitted)
    ratings.last.update!(status: :rejected)
    expect(described_class.new(target, admin).close).to be true
    expect(ratings.first.reload).to be_approved
    expect(ratings.last.reload).to be_rejected
    expect(AssessmentPeriod.current).to eq(target)
  end
end
