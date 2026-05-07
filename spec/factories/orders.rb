FactoryBot.define do
  factory :order do
    source_account { association :account }
    destination_account { association :account }
    initiator { source_account.user }
    amount { 100 }
    status { :created }
    kind { :transfer }
    idempotency_key { SecureRandom.hex }
  end
end
