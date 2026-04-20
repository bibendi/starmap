class AddStatusToTeamTechnologies < ActiveRecord::Migration[8.1]
  def change
    add_column :team_technologies, :status, :string, null: false, default: "active"
    add_index :team_technologies, :status
  end
end
