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

ActiveRecord::Schema[8.1].define(version: 2026_04_12_190000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "action_plans", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "assigned_to_id"
    t.date "completed_at"
    t.text "completion_notes"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.date "due_date"
    t.string "priority", default: "medium", null: false
    t.integer "progress_percentage", default: 0
    t.bigint "quarter_id"
    t.string "status", default: "active", null: false
    t.bigint "technology_id"
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["active"], name: "index_action_plans_on_active"
    t.index ["assigned_to_id"], name: "index_action_plans_on_assigned_to_id"
    t.index ["created_by_id"], name: "index_action_plans_on_created_by_id"
    t.index ["due_date"], name: "index_action_plans_on_due_date"
    t.index ["priority"], name: "index_action_plans_on_priority"
    t.index ["quarter_id"], name: "index_action_plans_on_quarter_id"
    t.index ["status"], name: "index_action_plans_on_status"
    t.index ["technology_id"], name: "index_action_plans_on_technology_id"
    t.index ["user_id"], name: "index_action_plans_on_user_id"
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "quarters", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.text "description"
    t.date "end_date", null: false
    t.date "evaluation_end_date"
    t.date "evaluation_start_date"
    t.boolean "is_current", default: false, null: false
    t.string "name", null: false
    t.integer "quarter_number", null: false
    t.date "start_date", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.integer "year", null: false
    t.index ["created_by_id"], name: "index_quarters_on_created_by_id"
    t.index ["end_date"], name: "index_quarters_on_end_date"
    t.index ["is_current"], name: "index_quarters_on_is_current"
    t.index ["name", "year"], name: "index_quarters_on_name_and_year", unique: true
    t.index ["start_date"], name: "index_quarters_on_start_date"
    t.index ["status"], name: "index_quarters_on_status"
    t.index ["year", "quarter_number"], name: "index_quarters_on_year_and_quarter_number", unique: true
  end

  create_table "skill_ratings", force: :cascade do |t|
    t.datetime "approved_at"
    t.bigint "approved_by_id"
    t.text "comment"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.bigint "quarter_id", null: false
    t.integer "rating", null: false
    t.string "status", default: "draft", null: false
    t.bigint "team_id", null: false
    t.bigint "technology_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.bigint "user_id", null: false
    t.index ["approved_by_id"], name: "index_skill_ratings_on_approved_by_id"
    t.index ["created_by_id"], name: "index_skill_ratings_on_created_by_id"
    t.index ["quarter_id"], name: "index_skill_ratings_on_quarter_id"
    t.index ["rating"], name: "index_skill_ratings_on_rating"
    t.index ["status"], name: "index_skill_ratings_on_status"
    t.index ["team_id", "quarter_id"], name: "index_skill_ratings_on_team_id_and_quarter_id"
    t.index ["team_id"], name: "index_skill_ratings_on_team_id"
    t.index ["technology_id"], name: "index_skill_ratings_on_technology_id"
    t.index ["updated_by_id"], name: "index_skill_ratings_on_updated_by_id"
    t.index ["user_id", "technology_id", "quarter_id"], name: "idx_on_user_id_technology_id_quarter_id_2dd6e152f0", unique: true
    t.index ["user_id"], name: "index_skill_ratings_on_user_id"
  end

  create_table "team_technologies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "criticality", default: "normal", null: false
    t.integer "target_experts", default: 2, null: false
    t.bigint "team_id", null: false
    t.bigint "technology_id", null: false
    t.datetime "updated_at", null: false
    t.index ["criticality"], name: "index_team_technologies_on_criticality"
    t.index ["team_id", "technology_id"], name: "index_team_technologies_on_team_and_tech", unique: true
    t.index ["team_id"], name: "index_team_technologies_on_team_id"
    t.index ["technology_id"], name: "index_team_technologies_on_technology_id"
  end

  create_table "teams", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.bigint "team_lead_id"
    t.bigint "unit_id"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_teams_on_active"
    t.index ["name"], name: "index_teams_on_name", unique: true
    t.index ["team_lead_id"], name: "index_teams_on_team_lead_id"
    t.index ["unit_id"], name: "index_teams_on_unit_id"
  end

  create_table "technologies", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.bigint "category_id"
    t.datetime "created_at", null: false
    t.bigint "created_by_id"
    t.string "criticality", default: "normal", null: false
    t.text "description"
    t.string "name", null: false
    t.integer "sort_order", default: 0
    t.integer "target_experts", default: 2
    t.datetime "updated_at", null: false
    t.bigint "updated_by_id"
    t.index ["active"], name: "index_technologies_on_active"
    t.index ["category_id"], name: "index_technologies_on_category_id"
    t.index ["created_by_id"], name: "index_technologies_on_created_by_id"
    t.index ["criticality"], name: "index_technologies_on_criticality"
    t.index ["name"], name: "index_technologies_on_name", unique: true
    t.index ["sort_order"], name: "index_technologies_on_sort_order"
    t.index ["updated_by_id"], name: "index_technologies_on_updated_by_id"
  end

  create_table "units", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "unit_lead_id"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_units_on_active"
    t.index ["name"], name: "index_units_on_name", unique: true
    t.index ["unit_lead_id"], name: "index_units_on_unit_lead_id"
  end

  create_table "users", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.string "avatar_url"
    t.datetime "confirmation_sent_at"
    t.datetime "confirmed_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "current_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "department"
    t.string "display_name"
    t.string "email", default: "", null: false
    t.string "employee_id"
    t.string "encrypted_password", default: "", null: false
    t.string "first_name", null: false
    t.string "last_name", null: false
    t.datetime "last_sign_in_at"
    t.string "last_sign_in_ip"
    t.string "phone"
    t.string "position"
    t.string "provider"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "role", default: "engineer", null: false
    t.integer "sign_in_count", default: 0, null: false
    t.integer "team_id"
    t.string "uid"
    t.string "unconfirmed_email"
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["provider", "uid"], name: "index_users_on_provider_and_uid", unique: true
    t.index ["role"], name: "index_users_on_role"
    t.index ["team_id"], name: "index_users_on_team_id"
  end

  add_foreign_key "action_plans", "quarters"
  add_foreign_key "action_plans", "technologies"
  add_foreign_key "action_plans", "users"
  add_foreign_key "action_plans", "users", column: "assigned_to_id"
  add_foreign_key "action_plans", "users", column: "created_by_id"
  add_foreign_key "quarters", "users", column: "created_by_id"
  add_foreign_key "skill_ratings", "quarters"
  add_foreign_key "skill_ratings", "teams"
  add_foreign_key "skill_ratings", "technologies"
  add_foreign_key "skill_ratings", "users"
  add_foreign_key "skill_ratings", "users", column: "approved_by_id"
  add_foreign_key "skill_ratings", "users", column: "created_by_id"
  add_foreign_key "skill_ratings", "users", column: "updated_by_id"
  add_foreign_key "team_technologies", "teams"
  add_foreign_key "team_technologies", "technologies"
  add_foreign_key "teams", "units"
  add_foreign_key "teams", "users", column: "team_lead_id"
  add_foreign_key "technologies", "categories"
  add_foreign_key "technologies", "users", column: "created_by_id"
  add_foreign_key "technologies", "users", column: "updated_by_id"
  add_foreign_key "units", "users", column: "unit_lead_id"
  add_foreign_key "users", "teams"
end
