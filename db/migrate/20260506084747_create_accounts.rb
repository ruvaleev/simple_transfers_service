class CreateAccounts < ActiveRecord::Migration[8.0]
  def change
    create_table :accounts do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :balance, precision: 19, scale: 4, default: 0, null: false

      t.timestamps

      t.check_constraint 'balance >= 0', name: 'accounts_balance_positive'
    end
  end
end
