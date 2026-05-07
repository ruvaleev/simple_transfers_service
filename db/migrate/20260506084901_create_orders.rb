class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.references :initiator, polymorphic: true, null: false
      t.references :source_account, null: false, foreign_key: { to_table: :accounts }
      t.references :destination_account, null: false, foreign_key: { to_table: :accounts }
      t.integer :status, null: false, default: 0
      t.integer :kind, null: false, default: 0
      t.decimal :amount, precision: 19, scale: 4, null: false, default: 0
      t.string :idempotency_key, null: false, index: { unique: true }

      t.timestamps

      t.check_constraint 'amount >= 0', name: 'orders_amount_positive'
      t.check_constraint 'source_account_id <> destination_account_id', name: 'orders_source_destination_different'
    end
  end
end
