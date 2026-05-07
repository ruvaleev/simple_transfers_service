class User < ApplicationRecord
  has_many :accounts, dependent: :restrict_with_exception
  has_many :initiated_orders, class_name: :Order, as: :initiator, foreign_key: :initiator_id,
                              inverse_of: :initiator, dependent: :restrict_with_exception

  validates :name, presence: true
end
