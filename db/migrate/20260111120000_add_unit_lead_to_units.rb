class AddUnitLeadToUnits < ActiveRecord::Migration[8.1]
  def change
    add_reference :units, :unit_lead, foreign_key: { to_table: :users }, null: true
  end
end
