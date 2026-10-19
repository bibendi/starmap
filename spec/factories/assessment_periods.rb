FactoryBot.define do
  sequence(:assessment_period_index) { |n| n }

  factory :assessment_period do
    transient do
      period_index { generate(:assessment_period_index) }
      year { Date.current.year + period_index / 4 }
      quarter_number { period_index % 4 + 1 }
    end

    period_kind { "quarterly" }
    start_date { Date.new(year, (quarter_number - 1) * 3 + 1, 1) }
    end_date { start_date&.end_of_quarter }
    evaluation_start_date { end_date }
    evaluation_end_date { evaluation_start_date ? evaluation_start_date + 14.days : nil }
    status { "closed" }
    is_current { false }

    before(:create) do |period|
      AssessmentPeriod.where(is_current: true).update_all(is_current: false) if period.is_current?
    end

    trait :current do
      is_current { true }
      status { "active" }
    end

    trait :active do
      status { "active" }
    end

    trait :draft do
      status { "draft" }
    end

    trait :closed do
      status { "closed" }
    end

    trait :archived do
      status { "archived" }
    end

    trait :previous do
      transient { relative_to { nil } }
      after(:build) do |period, evaluator|
        next unless evaluator.relative_to

        period.start_date = evaluator.relative_to.start_date.prev_quarter.beginning_of_quarter
        period.end_date = period.start_date.end_of_quarter
        period.evaluation_start_date = period.end_date
        period.evaluation_end_date = period.end_date + 14.days
      end
    end
  end
end
