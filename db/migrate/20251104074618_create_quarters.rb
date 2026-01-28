class CreateQuarters < ActiveRecord::Migration[8.1]
  def change
    create_table :quarters do |t|
      t.string :name, null: false
      t.integer :year, null: false
      t.integer :quarter_number, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.date :evaluation_start_date
      t.date :evaluation_end_date
      t.string :status, null: false, default: "active"
      t.text :description
      t.boolean :is_current, default: false
      t.references :previous_quarter, foreign_key: {to_table: :quarters}
      t.references :created_by, foreign_key: {to_table: :users}

      t.timestamps
    end

    # Indexes for performance
    add_index :quarters, [:year, :quarter_number], unique: true
    add_index :quarters, :status
    add_index :quarters, :is_current
    add_index :quarters, :start_date
    add_index :quarters, :end_date
  end
end
