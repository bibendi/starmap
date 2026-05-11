# ApiClient factory for testing
FactoryBot.define do
  factory :api_client do
    sequence(:name) { |n| "ci-agent-#{n}" }
    sequence(:oidc_client_id) { |n| "starmap-ci-agent-#{n}" }
    permissions { ["teams:read"] }
    enabled { true }

    transient do
      team_list { [] }
    end

    after(:build) do |client, evaluator|
      client.team_ids = evaluator.team_list.map(&:id) if evaluator.team_list.any?
    end

    trait :enabled do
      enabled { true }
    end

    trait :disabled do
      enabled { false }
    end
  end
end
