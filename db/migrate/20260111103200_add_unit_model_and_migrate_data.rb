# rubocop:disable Rails/ThreeStateBooleanColumn
class AddUnitModelAndMigrateData < ActiveRecord::Migration[8.1]
  def up
    create_table :units do |t|
      t.string :name, null: false
      t.text :description
      t.boolean :active, default: true
      t.integer :sort_order, default: 0

      t.timestamps
    end

    add_index :units, :name, unique: true
    add_index :units, :active
    add_index :units, :sort_order

    add_column :teams, :unit_id, :bigint
    add_foreign_key :teams, :units
    add_index :teams, :unit_id

    # Data migration: create units from existing unit_name values
    reversible do |dir|
      dir.up do
        # Find distinct unit_names
        unit_names = Team.distinct.pluck(:unit_name).compact
        unit_names.each do |name|
          unit = Unit.create!(name: name, description: "Unit #{name}")
          Team.where(unit_name: name).update_all(unit_id: unit.id)
        end
      end
      dir.down do
        # On rollback, set unit_name back from unit association
        Team.joins(:unit).find_each do |team|
          team.update_column(:unit_name, team.unit.name)
        end
      end
    end

    # Remove unit_name column after data migration
    remove_column :teams, :unit_name, :string
  end

  def down
    add_column :teams, :unit_name, :string

    # Restore unit_name from unit association
    Team.joins(:unit).find_each do |team|
      team.update_column(:unit_name, team.unit.name)
    end

    remove_foreign_key :teams, :units
    remove_index :teams, :unit_id
    remove_column :teams, :unit_id

    drop_table :units
  end
end
# rubocop:enable Rails/ThreeStateBooleanColumn
