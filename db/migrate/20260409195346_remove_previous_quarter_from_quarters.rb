class RemovePreviousQuarterFromQuarters < ActiveRecord::Migration[8.1]
  def up
    remove_foreign_key :quarters, column: :previous_quarter_id
    remove_reference :quarters, :previous_quarter, index: true
  end

  def down
    add_reference :quarters, :previous_quarter, foreign_key: {to_table: :quarters}, index: true
  end
end
