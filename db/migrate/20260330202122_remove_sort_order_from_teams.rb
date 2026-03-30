class RemoveSortOrderFromTeams < ActiveRecord::Migration[8.1]
  def change
    remove_index :teams, :sort_order
    remove_column :teams, :sort_order, :integer
  end
end
