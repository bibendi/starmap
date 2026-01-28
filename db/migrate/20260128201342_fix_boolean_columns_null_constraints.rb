class FixBooleanColumnsNullConstraints < ActiveRecord::Migration[8.1]
  def change
    # Users table
    change_column_null :users, :confirmed_at, false, false
    change_column_null :users, :active, false, true
    change_column_null :users, :admin, false, false

    # Teams table
    change_column_null :teams, :active, false, true

    # Technologies table
    change_column_null :technologies, :active, false, true

    # Quarters table
    change_column_null :quarters, :is_current, false, false

    # SkillRatings table
    change_column_null :skill_ratings, :locked, false, false

    # ActionPlans table
    change_column_null :action_plans, :active, false, true

    # Units table
    change_column_null :units, :active, false, true
  end
end
