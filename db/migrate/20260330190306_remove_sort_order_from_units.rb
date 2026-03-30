class RemoveSortOrderFromUnits < ActiveRecord::Migration[8.1]
  def change
    remove_column :units, :sort_order, :integer
  end
end
