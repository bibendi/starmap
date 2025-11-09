# Quarter factory for testing
FactoryBot.define do
  factory :quarter do
    year { Date.current.year }
    quarter_number { ((Date.current.month - 1) / 3) + 1 }
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
