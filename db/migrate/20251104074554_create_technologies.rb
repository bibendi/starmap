class CreateTechnologies < ActiveRecord::Migration[8.1]
  def change
    create_table :technologies do |t|
      t.string :name, null: false
      t.text :description
      t.string :category
      t.string :criticality, null: false, default: "normal"
      t.integer :target_experts, default: 2
      t.integer :sort_order, default: 0
      t.boolean :active, default: true
      t.references :created_by, foreign_key: {to_table: :users}
      t.references :updated_by, foreign_key: {to_table: :users}

      t.timestamps
    end

    # Indexes for performance
    add_index :technologies, :name, unique: true
    add_index :technologies, :category
    add_index :technologies, :criticality
    add_index :technologies, :active
    add_index :technologies, :sort_order
  end
end
