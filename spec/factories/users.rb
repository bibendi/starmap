# User factory for testing
FactoryBot.define do
  sequence(:email) { |n| "user#{n}@example.com" }
  sequence(:first_name) { |n| "Test#{n}" }
  sequence(:last_name) { |n| "User#{n}" }

  factory :user do
    email { generate(:email) }
    password { "password123" }
    password_confirmation { "password123" }
    first_name { generate(:first_name) }
    last_name { generate(:last_name) }
    role { "engineer" }
    active { true }
    confirmed_at { Time.current }

    # Association with team (optional)
    team

    factory :engineer do
      role { "engineer" }
    end

    factory :team_lead do
      role { "team_lead" }
    end

    factory :unit_lead do
      role { "unit_lead" }
    end

    factory :admin do
      role { "admin" }
    end

    factory :inactive_user do
      active { false }
    end
  end
end
