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

ActiveRecord::Schema[8.0].define(version: 2025_12_29_114212) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "actions", force: :cascade do |t|
    t.bigint "visit_record_id", null: false
    t.bigint "customer_id", null: false
    t.bigint "user_id", null: false
    t.string "title"
    t.date "due_date"
    t.integer "status"
    t.datetime "completed_at"
    t.bigint "next_visit_record_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_actions_on_customer_id"
    t.index ["due_date"], name: "index_actions_on_due_date"
    t.index ["next_visit_record_id"], name: "index_actions_on_next_visit_record_id"
    t.index ["status"], name: "index_actions_on_status"
    t.index ["user_id"], name: "index_actions_on_user_id"
    t.index ["visit_record_id"], name: "index_actions_on_visit_record_id"
  end

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "branches", force: :cascade do |t|
    t.string "code"
    t.string "name"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_branches_on_code", unique: true
  end

  create_table "customers", force: :cascade do |t|
    t.string "customer_number"
    t.string "household_number"
    t.string "name"
    t.string "name_kana"
    t.string "postal_code"
    t.string "address"
    t.string "phone"
    t.bigint "branch_id", null: false
    t.date "last_visit_date"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_customers_on_branch_id"
    t.index ["customer_number"], name: "index_customers_on_customer_number", unique: true
    t.index ["household_number"], name: "index_customers_on_household_number"
    t.index ["name_kana"], name: "index_customers_on_name_kana"
  end

  create_table "diagnoses", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "user_id", null: false
    t.date "diagnosed_on"
    t.string "title"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_diagnoses_on_customer_id"
    t.index ["user_id"], name: "index_diagnoses_on_user_id"
  end

  create_table "family_members", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "name"
    t.string "name_kana"
    t.date "birth_date"
    t.string "relationship"
    t.integer "relationship_type"
    t.integer "generation"
    t.boolean "is_living"
    t.boolean "is_cohabitant"
    t.string "address"
    t.string "phone"
    t.string "occupation"
    t.string "workplace"
    t.string "ja_customer_number"
    t.text "notes"
    t.bigint "parent_member_id"
    t.bigint "spouse_member_id"
    t.integer "marriage_status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_family_members_on_customer_id"
    t.index ["ja_customer_number"], name: "index_family_members_on_ja_customer_number"
    t.index ["parent_member_id"], name: "index_family_members_on_parent_member_id"
    t.index ["spouse_member_id"], name: "index_family_members_on_spouse_member_id"
  end

  create_table "ja_customers", force: :cascade do |t|
    t.string "customer_number"
    t.string "household_number"
    t.string "name"
    t.string "name_kana"
    t.date "birth_date"
    t.string "postal_code"
    t.string "address"
    t.string "phone"
    t.bigint "branch_id", null: false
    t.decimal "deposit_balance"
    t.decimal "loan_balance"
    t.boolean "has_banking"
    t.boolean "has_mutual_aid"
    t.boolean "has_agriculture"
    t.boolean "has_funeral"
    t.boolean "has_gas"
    t.boolean "has_real_estate"
    t.datetime "last_synced_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_ja_customers_on_branch_id"
    t.index ["customer_number"], name: "index_ja_customers_on_customer_number", unique: true
    t.index ["household_number"], name: "index_ja_customers_on_household_number"
    t.index ["name_kana"], name: "index_ja_customers_on_name_kana"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name", null: false
    t.integer "role", default: 0, null: false
    t.bigint "branch_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_users_on_branch_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "visit_plans", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "user_id", null: false
    t.bigint "visit_type_id", null: false
    t.date "planned_date"
    t.time "planned_time"
    t.text "purpose"
    t.integer "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_visit_plans_on_customer_id"
    t.index ["planned_date"], name: "index_visit_plans_on_planned_date"
    t.index ["status"], name: "index_visit_plans_on_status"
    t.index ["user_id"], name: "index_visit_plans_on_user_id"
    t.index ["visit_type_id"], name: "index_visit_plans_on_visit_type_id"
  end

  create_table "visit_records", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.bigint "user_id", null: false
    t.bigint "visit_type_id", null: false
    t.datetime "visited_at"
    t.string "interviewee"
    t.text "content"
    t.text "customer_situation"
    t.bigint "visit_plan_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["customer_id"], name: "index_visit_records_on_customer_id"
    t.index ["user_id"], name: "index_visit_records_on_user_id"
    t.index ["visit_plan_id"], name: "index_visit_records_on_visit_plan_id"
    t.index ["visit_type_id"], name: "index_visit_records_on_visit_type_id"
    t.index ["visited_at"], name: "index_visit_records_on_visited_at"
  end

  create_table "visit_types", force: :cascade do |t|
    t.string "name"
    t.integer "display_order"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "actions", "customers"
  add_foreign_key "actions", "users"
  add_foreign_key "actions", "visit_records"
  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "customers", "branches"
  add_foreign_key "diagnoses", "customers"
  add_foreign_key "diagnoses", "users"
  add_foreign_key "family_members", "customers"
  add_foreign_key "ja_customers", "branches"
  add_foreign_key "users", "branches"
  add_foreign_key "visit_plans", "customers"
  add_foreign_key "visit_plans", "users"
  add_foreign_key "visit_plans", "visit_types"
  add_foreign_key "visit_records", "customers"
  add_foreign_key "visit_records", "users"
  add_foreign_key "visit_records", "visit_plans"
  add_foreign_key "visit_records", "visit_types"
end
