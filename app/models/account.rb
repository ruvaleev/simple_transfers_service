class Account < ApplicationRecord
  belongs_to :user

  with_options dependent: :restrict_with_exception do
    with_options class_name: :Order do
      has_many :incoming_orders, foreign_key: :destination_account_id, inverse_of: :destination_account
      has_many :outgoing_orders, foreign_key: :source_account_id, inverse_of: :source_account
    end

    has_many :ledger_entries
  end

  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :name, presence: true

  def calculated_balance
    ledger_entries.credits.sum(:amount) - ledger_entries.debits.sum(:amount)
  end
end
