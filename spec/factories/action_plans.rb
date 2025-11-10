# ActionPlan factory for testing
FactoryBot.define do
  sequence(:action_plan_title) { |n| "Action Plan #{n}" }

  factory :action_plan do
    title { generate(:action_plan_title) }
    description { "Description for #{title}" }
    status { "active" }
    priority { "medium" }
    progress_percentage { 0 }
    due_date { 30.days.from_now }

    # Associations
    association :created_by, factory: :user
    user
    technology
    quarter

    trait :completed do
      status { "completed" }
      progress_percentage { 100 }
      completed_at { Date.current }
    end

    trait :in_progress do
      status { "in_progress" }
      progress_percentage { 50 }
    end

    trait :cancelled do
      status { "cancelled" }
    end

    trait :postponed do
      status { "postponed" }
    end

    trait :high_priority do
      priority { "high" }
    end

    trait :critical_priority do
      priority { "critical" }
    end

    trait :low_priority do
      priority { "low" }
    end

    trait :assigned do
      association :assigned_to, factory: :user
    end

    trait :overdue do
      due_date { 1.day.ago }
    end

    trait :due_soon do
      due_date { 3.days.from_now }
    end
  end
end
