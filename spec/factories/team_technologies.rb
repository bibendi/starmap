# TeamTechnology factory for testing
FactoryBot.define do
  factory :team_technology do
    team { create(:team) }
    technology { create(:technology) }
    criticality { "normal" }
    target_experts { 2 }
    status { "active" }

    trait :high_criticality do
      criticality { "high" }
      target_experts { 3 }
    end

    trait :low_criticality do
      criticality { "low" }
      target_experts { 1 }
    end

    trait :archived do
      status { "archived" }
    end
  end
end
