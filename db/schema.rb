# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_05_06_085085) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "accounts", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", null: false
    t.decimal "balance", precision: 19, scale: 4, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_accounts_on_user_id"
    t.check_constraint "balance >= 0::numeric", name: "accounts_balance_positive"
  end

  create_table "ledger_entries", force: :cascade do |t|
    t.bigint "account_id", null: false
    t.bigint "order_id", null: false
    t.integer "direction", default: 0, null: false
    t.integer "entry_type", default: 0, null: false
    t.decimal "amount", precision: 19, scale: 4, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["account_id"], name: "index_ledger_entries_on_account_id"
    t.index ["order_id", "direction", "entry_type"], name: "index_ledger_entries_on_order_id_and_direction_and_entry_type", unique: true
    t.index ["order_id"], name: "index_ledger_entries_on_order_id"
    t.check_constraint "amount >= 0::numeric", name: "ledger_entries_amount_positive"
  end

  create_table "orders", force: :cascade do |t|
    t.string "initiator_type", null: false
    t.bigint "initiator_id", null: false
    t.bigint "source_account_id", null: false
    t.bigint "destination_account_id", null: false
    t.integer "status", default: 0, null: false
    t.integer "kind", default: 0, null: false
    t.decimal "amount", precision: 19, scale: 4, default: "0.0", null: false
    t.string "idempotency_key", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["destination_account_id"], name: "index_orders_on_destination_account_id"
    t.index ["idempotency_key"], name: "index_orders_on_idempotency_key", unique: true
    t.index ["initiator_type", "initiator_id"], name: "index_orders_on_initiator"
    t.index ["source_account_id"], name: "index_orders_on_source_account_id"
    t.check_constraint "amount >= 0::numeric", name: "orders_amount_positive"
    t.check_constraint "source_account_id <> destination_account_id", name: "orders_source_destination_different"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "accounts", "users"
  add_foreign_key "ledger_entries", "accounts"
  add_foreign_key "ledger_entries", "orders"
  add_foreign_key "orders", "accounts", column: "destination_account_id"
  add_foreign_key "orders", "accounts", column: "source_account_id"
end
