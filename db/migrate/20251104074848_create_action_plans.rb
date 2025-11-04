class CreateActionPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :action_plans do |t|
      t.string :title, null: false
      t.text :description
      t.references :user, foreign_key: true
      t.references :technology, foreign_key: true
      t.references :quarter, foreign_key: true
      t.references :created_by, foreign_key: { to_table: :users }
      t.references :assigned_to, foreign_key: { to_table: :users }
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
    add_index :action_plans, :user_id
    add_index :action_plans, :technology_id
    add_index :action_plans, :quarter_id
    add_index :action_plans, :created_by_id
    add_index :action_plans, :assigned_to_id
    add_index :action_plans, :status
    add_index :action_plans, :priority
    add_index :action_plans, :due_date
    add_index :action_plans, :active
  end
end
