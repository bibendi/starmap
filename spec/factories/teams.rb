# Team factory for testing
FactoryBot.define do
  sequence(:team_name) { |n| "Test Team #{n}" }

  factory :team do
    name { generate(:team_name) }
    unit { create(:unit) }

    trait :with_team_lead do
      transient do
        team_lead { nil }
      end

      after(:create) do |team, evaluator|
        if evaluator.team_lead.present?
          team.update!(team_lead_id: evaluator.team_lead.id)
        else
          team_lead = create(:team_lead)
          team.update!(team_lead_id: team_lead.id)
        end
      end
    end
  end
end
