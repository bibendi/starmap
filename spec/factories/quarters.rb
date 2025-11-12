# Quarter factory for testing
FactoryBot.define do
  sequence(:quarter_year) { |n| Date.current.year + (n / 4) }
  sequence(:quarter_number_seq) { |n| ((n % 4) + 1) }

  factory :quarter do
    year { generate(:quarter_year) }
    quarter_number { generate(:quarter_number_seq) }
    name { "#{year} Q#{quarter_number}" }
    start_date { Date.new(year, (quarter_number - 1) * 3 + 1, 1) }
    end_date { start_date.end_of_quarter }
    evaluation_start_date { start_date + 45.days }
    evaluation_end_date { evaluation_start_date + 14.days }
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

    trait :with_previous do
      after(:create) do |quarter|
        create(:quarter,
               year: quarter.year - (quarter.quarter_number == 1 ? 1 : 0),
               quarter_number: quarter.quarter_number == 1 ? 4 : quarter.quarter_number - 1,
               status: "closed")
      end
    end
  end
end
