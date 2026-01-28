class AddUniqueIndexToQuarterNameAndYear < ActiveRecord::Migration[8.1]
  def change
    add_index :quarters, [:name, :year], unique: true
  end
end
