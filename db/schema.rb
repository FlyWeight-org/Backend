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

ActiveRecord::Schema[7.1].define(version: 2022_03_07_051658) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "flights", force: :cascade do |t|
    t.bigint "pilot_id", null: false
    t.string "uuid", null: false
    t.date "date", null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["pilot_id"], name: "index_flights_on_pilot_id"
    t.index ["uuid"], name: "index_flights_on_uuid", unique: true
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti"
  end

  create_table "loads", force: :cascade do |t|
    t.bigint "flight_id", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.integer "weight", default: 0, null: false
    t.integer "bags_weight", default: 0, null: false
    t.boolean "covid19_vaccination", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["flight_id", "slug"], name: "index_loads_on_flight_id_and_slug", unique: true
    t.index ["flight_id"], name: "index_loads_on_flight_id"
  end

  create_table "pilots", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_pilots_on_email", unique: true
    t.index ["reset_password_token"], name: "index_pilots_on_reset_password_token", unique: true
  end

  add_foreign_key "flights", "pilots", on_delete: :cascade
  add_foreign_key "loads", "flights", on_delete: :cascade
end
