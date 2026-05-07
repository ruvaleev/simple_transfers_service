class LedgerEntry < ApplicationRecord
  belongs_to :account
  belongs_to :order

  enum :direction, { debit: 0, credit: 1 }
  enum :entry_type, { normal: 0, reversal: 1 }

  validates :amount, numericality: { greater_than: 0 }
  validates :order_id, uniqueness: { scope: %i[direction entry_type] }

  scope :credits, -> { where(direction: :credit) }
  scope :debits,  -> { where(direction: :debit) }
  scope :normals, -> { where(entry_type: :normal) }
  scope :reversals, -> { where(entry_type: :reversal) }

  def readonly?
    persisted?
  end
end
