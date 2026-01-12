class CreateTeamTechnologies < ActiveRecord::Migration[8.1]
  def change
    create_table :team_technologies do |t|
      t.references :team, null: false, foreign_key: true
      t.references :technology, null: false, foreign_key: true
      t.string :criticality, default: 'normal', null: false
      t.integer :target_experts, default: 2, null: false

      t.timestamps

      t.index [:team_id, :technology_id], unique: true, name: 'index_team_technologies_on_team_and_tech'
      t.index [:criticality], name: 'index_team_technologies_on_criticality'
    end
  end
end
