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

ActiveRecord::Schema.define(version: 2020_09_18_105527) do

  create_table "actions", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "tenancy_ref"
    t.string "payment_ref"
    t.float "balance"
    t.string "patch_code"
    t.string "classification"
    t.string "pause_reason"
    t.text "pause_comment"
    t.datetime "pause_until"
    t.string "action_type"
    t.string "service_area_type"
    t.json "metadata"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["tenancy_ref"], name: "index_actions_on_tenancy_ref", unique: true
  end

  create_table "agreement_legacy_migrations", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.bigint "legacy_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "agreement_id"
    t.index ["agreement_id"], name: "index_agreement_legacy_migrations_on_agreement_id"
  end

  create_table "agreement_states", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.bigint "agreement_id"
    t.string "agreement_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "checked_balance", precision: 10, scale: 2
    t.decimal "expected_balance", precision: 10, scale: 2
    t.string "description"
    t.index ["agreement_id"], name: "index_agreement_states_on_agreement_id"
  end

  create_table "agreements", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "agreement_type"
    t.decimal "starting_balance", precision: 10, scale: 2
    t.decimal "amount", precision: 10, scale: 2
    t.datetime "start_date"
    t.integer "frequency"
    t.string "current_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "tenancy_ref", null: false
    t.string "created_by", null: false
    t.text "notes"
    t.bigint "court_case_id"
    t.decimal "initial_payment_amount", precision: 10, scale: 2
    t.datetime "initial_payment_date"
    t.index ["court_case_id"], name: "index_agreements_on_court_case_id"
  end

  create_table "case_priorities", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "tenancy_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "balance", precision: 10, scale: 2
    t.integer "days_in_arrears"
    t.integer "days_since_last_payment"
    t.boolean "nosp_served"
    t.boolean "active_nosp"
    t.bigint "assigned_user_id"
    t.datetime "is_paused_until"
    t.string "pause_reason"
    t.text "pause_comment"
    t.bigint "case_id"
    t.datetime "nosp_served_date"
    t.datetime "nosp_expiry_date"
    t.decimal "weekly_rent", precision: 10, scale: 2
    t.string "last_communication_action"
    t.datetime "last_communication_date"
    t.integer "classification"
    t.string "patch_code"
    t.datetime "courtdate"
    t.string "court_outcome"
    t.datetime "eviction_date"
    t.datetime "universal_credit"
    t.datetime "uc_rent_verification"
    t.datetime "uc_direct_payment_requested"
    t.datetime "uc_direct_payment_received"
    t.string "payment_ref"
    t.decimal "collectable_arrears", precision: 10, scale: 2
    t.index ["assigned_user_id"], name: "index_case_priorities_on_assigned_user_id"
    t.index ["case_id"], name: "index_case_priorities_on_case_id"
    t.index ["tenancy_ref"], name: "index_case_priorities_on_tenancy_ref", unique: true
  end

  create_table "cases", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "tenancy_ref"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "court_cases", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.datetime "court_date"
    t.text "court_outcome"
    t.decimal "balance_on_court_outcome_date", precision: 10, scale: 2
    t.string "tenancy_ref", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "strike_out_date"
    t.boolean "terms"
    t.boolean "disrepair_counter_claim"
  end

  create_table "delayed_jobs", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
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

  create_table "documents", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "uuid", null: false
    t.string "extension", null: false
    t.text "metadata"
    t.string "filename"
    t.string "url"
    t.string "mime_type", null: false
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "ext_message_id"
    t.string "username"
    t.string "email"
    t.index ["uuid"], name: "index_documents_on_uuid", unique: true
  end

  create_table "evictions", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.datetime "date", null: false
    t.string "tenancy_ref", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "users", options: "ENGINE=InnoDB DEFAULT CHARSET=latin1", force: :cascade do |t|
    t.string "provider_uid"
    t.string "provider"
    t.string "name"
    t.string "email"
    t.string "first_name"
    t.string "last_name"
    t.string "provider_permissions"
    t.integer "role", default: 0
  end

  add_foreign_key "agreement_legacy_migrations", "agreements"
  add_foreign_key "agreements", "court_cases"
  add_foreign_key "case_priorities", "users", column: "assigned_user_id"
end
