FactoryBot.define do
  factory :category do
    sequence(:name) { |n| "Category #{n}" }

    trait :with_technology do
      after(:create) do |category|
        create(:technology, category: category)
      end
    end
  end
end
