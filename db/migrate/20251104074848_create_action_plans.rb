class CreateActionPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :action_plans do |t|
      t.string :title, null: false
      t.text :description
      t.integer :user_id  # Will add foreign key constraint later
      t.integer :technology_id  # Will add foreign key constraint later
      t.integer :quarter_id  # Will add foreign key constraint later
      t.integer :created_by_id  # Will add foreign key constraint later
      t.integer :assigned_to_id  # Will add foreign key constraint later
      t.string :status, null: false, default: 'active'
      t.string :priority, null: false, default: 'medium'
      t.date :due_date
      t.date :completed_at
      t.text :completion_notes
      t.integer :progress_percentage, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    # Indexes for performance
    add_index :action_plans, :created_by_id
    add_index :action_plans, :assigned_to_id
    add_index :action_plans, :status
    add_index :action_plans, :priority
    add_index :action_plans, :due_date
    add_index :action_plans, :active
  end
end
