FactoryBot.define do
  factory :ledger_entry do
    association :account
    association :order
    amount { rand(1_000) }
  end
end
