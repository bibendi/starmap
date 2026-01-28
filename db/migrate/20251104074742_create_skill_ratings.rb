class CreateSkillRatings < ActiveRecord::Migration[8.1]
  def change
    create_table :skill_ratings do |t|
      t.references :user, null: false, foreign_key: true
      t.references :technology, null: false, foreign_key: true
      t.references :quarter, null: false, foreign_key: true
      t.integer :rating, null: false
      t.text :comment
      t.string :status, null: false, default: "draft"
      t.references :approved_by, foreign_key: {to_table: :users}
      t.datetime :approved_at
      t.references :created_by, foreign_key: {to_table: :users}
      t.references :updated_by, foreign_key: {to_table: :users}
      t.boolean :locked, default: false

      t.timestamps
    end

    # Unique constraint to prevent duplicate ratings for same user/technology/quarter
    add_index :skill_ratings, [:user_id, :technology_id, :quarter_id], unique: true

    # Indexes for performance
    add_index :skill_ratings, :rating
    add_index :skill_ratings, :status
    add_index :skill_ratings, :locked
  end
end
