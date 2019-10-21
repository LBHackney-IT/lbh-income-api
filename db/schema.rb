# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2019_10_21_141505) do

  create_table "case_priorities", force: :cascade do |t|
    t.string "tenancy_ref"
    t.string "priority_band"
    t.integer "priority_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "balance_contribution"
    t.decimal "days_in_arrears_contribution"
    t.decimal "days_since_last_payment_contribution"
    t.decimal "payment_amount_delta_contribution"
    t.decimal "payment_date_delta_contribution"
    t.decimal "number_of_broken_agreements_contribution"
    t.decimal "active_agreement_contribution"
    t.decimal "broken_court_order_contribution"
    t.decimal "nosp_served_contribution"
    t.decimal "active_nosp_contribution"
    t.decimal "balance", precision: 10, scale: 2
    t.integer "days_in_arrears"
    t.integer "days_since_last_payment"
    t.decimal "payment_amount_delta"
    t.integer "payment_date_delta"
    t.integer "number_of_broken_agreements"
    t.boolean "active_agreement"
    t.boolean "broken_court_order"
    t.boolean "nosp_served"
    t.boolean "active_nosp"
    t.integer "assigned_user_id"
    t.datetime "is_paused_until"
    t.string "pause_reason"
    t.text "pause_comment"
    t.integer "case_id"
    t.datetime "nosp_served_date"
    t.datetime "nosp_expiry_date"
    t.decimal "weekly_rent", precision: 10, scale: 2
    t.string "last_communication_action"
    t.datetime "last_communication_date"
    t.integer "classification"
    t.string "patch_code"
    t.datetime "courtdate"
    t.index ["assigned_user_id"], name: "index_case_priorities_on_assigned_user_id"
    t.index ["case_id"], name: "index_case_priorities_on_case_id"
    t.index ["tenancy_ref"], name: "index_case_priorities_on_tenancy_ref", unique: true
  end

  create_table "cases", force: :cascade do |t|
    t.string "tenancy_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "delayed_jobs", force: :cascade do |t|
    t.integer "priority", default: 0, null: false
    t.integer "attempts", default: 0, null: false
    t.text "handler", null: false
    t.text "last_error"
    t.datetime "run_at"
    t.datetime "locked_at"
    t.datetime "failed_at"
    t.string "locked_by"
    t.string "queue"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["priority", "run_at"], name: "delayed_jobs_priority"
  end

  create_table "documents", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "extension", null: false
    t.string "metadata"
    t.string "filename"
    t.string "url"
    t.string "mime_type", null: false
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ext_message_id"
    t.index ["uuid"], name: "index_documents_on_uuid", unique: true
  end

  create_table "users", force: :cascade do |t|
    t.string "provider_uid"
    t.string "provider"
    t.string "name"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "provider_permissions"
    t.integer "role", default: 0
  end

end
