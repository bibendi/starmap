# Technology factory for testing
FactoryBot.define do
  sequence(:technology_name) { |n| "Technology #{n}" }

  factory :technology do
    name { generate(:technology_name) }
    description { "Description for #{name}" }
    criticality { "normal" }
    target_experts { 2 }
    active { true }
    sort_order { 1 }

    transient do
      category_name { nil }
    end

    after(:build) do |technology, evaluator|
      if evaluator.category_name
        technology.category = Category.find_or_create_by!(name: evaluator.category_name)
      end
    end

    trait :high_criticality do
      criticality { "high" }
      target_experts { 3 }
    end

    trait :low_criticality do
      criticality { "low" }
      target_experts { 1 }
    end

    trait :inactive do
      active { false }
    end
  end
end
