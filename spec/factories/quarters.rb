# Quarter factory for testing
FactoryBot.define do
  sequence(:quarter_year) { |n| Date.current.year + (n / 4) }
  sequence(:quarter_number_seq) { |n| (n % 4) + 1 }

  factory :quarter do
    year { generate(:quarter_year) }
    quarter_number { generate(:quarter_number_seq) }
    name { "#{year} Q#{quarter_number}" }
    start_date { Date.new(year, (quarter_number - 1) * 3 + 1, 1) }
    end_date { start_date&.end_of_quarter }
    evaluation_start_date { end_date }
    evaluation_end_date { evaluation_start_date ? evaluation_start_date + 14.days : nil }
    status { "active" }
    is_current { false }
    description { "Test quarter #{name}" }

    trait :current do
      is_current { true }
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
      transient do
        relative_to { nil }
      end

      after(:build) do |quarter, evaluator|
        if evaluator.relative_to
          quarter.year = evaluator.relative_to.year - ((evaluator.relative_to.quarter_number == 1) ? 1 : 0)
          quarter.quarter_number = (evaluator.relative_to.quarter_number == 1) ? 4 : evaluator.relative_to.quarter_number - 1
          quarter.name = "#{quarter.year} Q#{quarter.quarter_number}"
          quarter.start_date = Date.new(quarter.year, (quarter.quarter_number - 1) * 3 + 1, 1)
          quarter.end_date = quarter.start_date.end_of_quarter
          quarter.evaluation_start_date = quarter.end_date
          quarter.evaluation_end_date = quarter.evaluation_start_date + 14.days
        end
      end
    end
  end
end
