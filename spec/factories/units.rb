# Unit factory for testing
FactoryBot.define do
  sequence(:unit_name) { |n| "Unit #{n}" }

  factory :unit do
    name { generate(:unit_name) }
    description { "Test unit description" }
    active { true }
    sort_order { 0 }
  end
end
