class CreateLedgerEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :ledger_entries do |t|
      t.references :account, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true, index: false
      t.integer :direction, null: false, default: 0
      t.integer :entry_type, null: false, default: 0
      t.decimal :amount, precision: 19, scale: 4, null: false

      t.timestamps

      t.check_constraint 'amount >= 0', name: 'ledger_entries_amount_positive'
    end

    add_index :ledger_entries, %i[order_id direction entry_type], unique: true
  end
end
