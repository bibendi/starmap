class RemoveLockedFromSkillRatings < ActiveRecord::Migration[8.1]
  def change
    remove_column :skill_ratings, :locked, :boolean, default: false, null: false
  end
end
