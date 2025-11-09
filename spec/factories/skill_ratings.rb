# SkillRating factory for testing
FactoryBot.define do
  factory :skill_rating do
    user
    technology
    quarter
    rating { rand(0..3) }
    status { "draft" }
    comment { "Test comment" }
    locked { false }

    trait :approved do
      rating { [1, 2, 3].sample } # Can't be 0 for approved ratings
      status { "approved" }
      approved_at { Time.current }
      association :approved_by, factory: :user
    end

    trait :submitted do
      status { "submitted" }
    end

    trait :rejected do
      status { "rejected" }
      approved_at { Time.current }
      association :approved_by, factory: :user
    end

    trait :locked do
      locked { true }
    end

    trait :expert_level do
      rating { [2, 3].sample }
    end

    trait :novice_level do
      rating { [0, 1].sample }
    end

    trait :own_rating do
      association :user, factory: :engineer
    end

    trait :team_lead_rating do
      association :user, factory: :team_lead
    end

    trait :other_team_rating do
      association :user, factory: :engineer
      after(:create) do |rating|
        other_team = create(:team)
        rating.user.update!(team: other_team)
      end
    end
  end
end
