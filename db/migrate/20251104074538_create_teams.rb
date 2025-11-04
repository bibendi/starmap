class CreateTeams < ActiveRecord::Migration[8.1]
  def change
    create_table :teams do |t|
      t.string :name, null: false
      t.string :description
      t.string :unit_name
      t.integer :team_lead_id  # Will add foreign key constraint later
      t.string :ldap_group_dn
      t.boolean :active, default: true
      t.integer :sort_order, default: 0

      t.timestamps
    end

    # Indexes for performance
    add_index :teams, :name, unique: true
    add_index :teams, :unit_name
    add_index :teams, :team_lead_id
    add_index :teams, :active
    add_index :teams, :sort_order
  end
end
