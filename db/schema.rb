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

ActiveRecord::Schema[8.1].define(version: 2026_04_16_000005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "account_jwt_refresh_keys", force: :cascade do |t|
    t.datetime "deadline", null: false
    t.string "key", null: false
    t.bigint "pilot_id", null: false
    t.index ["key"], name: "index_account_jwt_refresh_keys_on_key", unique: true
    t.index ["pilot_id"], name: "index_account_jwt_refresh_keys_on_pilot_id"
  end

  create_table "account_password_reset_keys", force: :cascade do |t|
    t.datetime "deadline", null: false
    t.datetime "email_last_sent", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "key", null: false
  end

  create_table "account_webauthn_keys", primary_key: ["account_id", "webauthn_id"], force: :cascade do |t|
    t.bigint "account_id", null: false
    t.string "label"
    t.datetime "last_use", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.string "public_key", null: false
    t.integer "sign_count", default: 0, null: false
    t.string "webauthn_id", null: false
  end

  create_table "account_webauthn_user_ids", force: :cascade do |t|
    t.string "webauthn_id", null: false
  end

  create_table "flights", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.string "description"
    t.bigint "pilot_id", null: false
    t.datetime "updated_at", null: false
    t.string "uuid", null: false
    t.index ["pilot_id"], name: "index_flights_on_pilot_id"
    t.index ["uuid"], name: "index_flights_on_uuid", unique: true
  end

  create_table "loads", force: :cascade do |t|
    t.integer "bags_weight", default: 0, null: false
    t.boolean "covid19_vaccination", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "flight_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.integer "weight", default: 0, null: false
    t.index ["flight_id", "slug"], name: "index_loads_on_flight_id_and_slug", unique: true
    t.index ["flight_id"], name: "index_loads_on_flight_id"
  end

  create_table "pilots", force: :cascade do |t|
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "name", null: false
    t.string "password_hash"
    t.integer "status_id", default: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_pilots_on_email", unique: true
  end

  add_foreign_key "account_jwt_refresh_keys", "pilots", on_delete: :cascade
  add_foreign_key "account_password_reset_keys", "pilots", column: "id", on_delete: :cascade
  add_foreign_key "account_webauthn_keys", "pilots", column: "account_id", on_delete: :cascade
  add_foreign_key "account_webauthn_user_ids", "pilots", column: "id", on_delete: :cascade
  add_foreign_key "flights", "pilots", on_delete: :cascade
  add_foreign_key "loads", "flights", on_delete: :cascade
end
