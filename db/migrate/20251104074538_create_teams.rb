class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :description
      t.string :unit_name
      t.references :team_lead, foreign_key: { to_table: :users }
      t.string :ldap_group_dn
      t.boolean :active, default: true
      t.integer :sort_order, default: 0

      t.timestamps
    end

    # Indexes for performance
    add_index :teams, :name, unique: true
    add_index :teams, :unit_name
    add_index :teams, :active
    add_index :teams, :sort_order

    # Add team_id to existing users table
    add_column :users, :team_id, :integer
    add_index :users, :team_id
    add_foreign_key :users, :teams
  end
end
