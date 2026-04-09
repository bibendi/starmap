class RemoveAdminFromUsers < ActiveRecord::Migration[8.1]
  def up
    remove_column :users, :admin, :boolean, default: false, null: false
  end

  def down
    add_column :users, :admin, :boolean, default: false, null: false
  end
end
