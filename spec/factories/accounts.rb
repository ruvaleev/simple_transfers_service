FactoryBot.define do
  factory :account do
    association :user
    balance { rand(1_000) }
    sequence(:name) { |i| "Account #{i}" }
  end
end
