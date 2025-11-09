# Technology factory for testing
FactoryBot.define do
  sequence(:technology_name) { |n| "Technology #{n}" }

  factory :technology do
    name { generate(:technology_name) }
    description { "Description for #{name}" }
    category { "Backend" }
    criticality { "normal" }
    target_experts { 2 }
    active { true }
    sort_order { 1 }

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
