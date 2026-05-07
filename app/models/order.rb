class Order < ApplicationRecord
  belongs_to :destination_account, class_name: :Account
  belongs_to :initiator, polymorphic: true
  belongs_to :source_account, class_name: :Account

  has_many :ledger_entries, dependent: :restrict_with_exception

  enum :kind, { transfer: 0, fee: 1, deposit: 2 }
  enum :status, { created: 0, successful: 1, cancelled: 2 }

  validates :amount, numericality: { greater_than: 0 }
  validates :idempotency_key, presence: true, uniqueness: true

  validate :destination_account_is_valid
  validate :source_account_is_valid

  scope :by_user_id, ->(user_id) {
    account_ids = Account.where(user_id: user_id).select(:id)
    where(source_account_id: account_ids)
      .or(where(destination_account_id: account_ids))
  }

  def internal?
    destination_account_id === source_account_id
  end

  private

  def destination_account_is_valid
    return if source_account_id.blank? || destination_account_id.blank?
    return if source_account_id != destination_account_id

    errors.add(:destination_account, 'must differ from source account')
  end

  def source_account_is_valid
    return if source_account_id.blank? || initiator_id.blank?
    return if source_account.user == initiator

    errors.add(:source_account, :invalid)
  end
end
