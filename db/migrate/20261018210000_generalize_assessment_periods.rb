# frozen_string_literal: true

require_relative "../../lib/assessment_period_migration_preflight"

class GeneralizeAssessmentPeriods < ActiveRecord::Migration[8.1]
  def up
    AssessmentPeriodMigrationPreflight.new(connection).validate!
    rename_table :quarters, :assessment_periods
    %i[skill_ratings action_plans].each { |table| rename_column table, :quarter_id, :assessment_period_id }
    remove_index :assessment_periods, [:year, :quarter_number]
    remove_index :assessment_periods, [:name, :year]
    remove_column :assessment_periods, :year, :integer
    remove_column :assessment_periods, :quarter_number, :integer
    add_column :assessment_periods, :period_kind, :string, null: false, default: "quarterly"
    change_column_default :assessment_periods, :status, from: "active", to: "draft"
    %i[evaluation_start_date evaluation_end_date].each { |column| change_column_null :assessment_periods, column, false }
    add_check_constraint :assessment_periods, "period_kind IN ('monthly', 'quarterly', 'semiannual', 'annual', 'custom')", name: "assessment_period_kind"
    add_check_constraint :assessment_periods, "end_date > start_date AND evaluation_start_date >= end_date AND evaluation_end_date > evaluation_start_date", name: "assessment_period_dates"
    add_exclusion_constraint :assessment_periods, "daterange(start_date, end_date, '[]') WITH &&", using: :gist, name: "assessment_periods_no_overlap"
    add_index :assessment_periods, :is_current, unique: true, where: "is_current", name: "one_current_assessment_period"
    add_index :assessment_periods, :status, unique: true, where: "status = 'active'", name: "one_active_assessment_period"
  end

  def down
    validate_rollback!
    remove_index :assessment_periods, name: "one_current_assessment_period"
    remove_index :assessment_periods, name: "one_active_assessment_period"
    remove_exclusion_constraint :assessment_periods, name: "assessment_periods_no_overlap"
    remove_check_constraint :assessment_periods, name: "assessment_period_dates"
    remove_check_constraint :assessment_periods, name: "assessment_period_kind"
    %i[evaluation_start_date evaluation_end_date].each { |column| change_column_null :assessment_periods, column, true }
    change_column_default :assessment_periods, :status, from: "draft", to: "active"
    add_column :assessment_periods, :year, :integer
    add_column :assessment_periods, :quarter_number, :integer
    execute "UPDATE assessment_periods SET year = EXTRACT(YEAR FROM start_date), quarter_number = EXTRACT(QUARTER FROM start_date)"
    %i[year quarter_number].each { |column| change_column_null :assessment_periods, column, false }
    remove_column :assessment_periods, :period_kind, :string
    add_index :assessment_periods, [:year, :quarter_number], unique: true
    add_index :assessment_periods, [:name, :year], unique: true
    %i[skill_ratings action_plans].each { |table| rename_column table, :assessment_period_id, :quarter_id }
    rename_table :assessment_periods, :quarters
  end

  private

  def validate_rollback!
    invalid = select_values(<<~SQL)
      SELECT id FROM assessment_periods
      WHERE period_kind <> 'quarterly'
         OR start_date <> date_trunc('quarter', start_date)::date
         OR end_date <> (date_trunc('quarter', start_date) + INTERVAL '3 months - 1 day')::date
    SQL
    duplicates = select_values(<<~SQL)
      SELECT name FROM assessment_periods GROUP BY name, EXTRACT(YEAR FROM start_date) HAVING COUNT(*) > 1
    SQL
    return if invalid.empty? && duplicates.empty?

    raise ActiveRecord::IrreversibleMigration, "Periods cannot be represented as quarters: ids=#{invalid.inspect}, duplicate names=#{duplicates.inspect}"
  end
end
