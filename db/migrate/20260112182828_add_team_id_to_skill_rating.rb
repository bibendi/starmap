class AddTeamIdToSkillRating < ActiveRecord::Migration[8.1]
  def change
    add_reference :skill_ratings, :team, null: false, foreign_key: true
    add_index :skill_ratings, [:team_id, :quarter_id]
  end
end
