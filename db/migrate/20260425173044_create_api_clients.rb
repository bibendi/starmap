class CreateApiClients < ActiveRecord::Migration[8.1]
  def change
    create_table :api_clients do |t|
      t.string :name, null: false
      t.string :oidc_client_id, null: false
      t.string :permissions, array: true, default: []
      t.integer :team_ids, array: true, default: []
      t.boolean :enabled, default: true, null: false

      t.timestamps
    end

    add_index :api_clients, :oidc_client_id, unique: true
    add_index :api_clients, :team_ids, using: :gin
    add_index :api_clients, :enabled
  end
end
