class CreateCategoriesAndMigrateTechnologiesCategory < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.timestamps
    end

    add_index :categories, :name, unique: true

    reversible do |dir|
      dir.up do
        execute <<~SQL
          INSERT INTO categories (name, created_at, updated_at)
          SELECT DISTINCT category, NOW(), NOW()
          FROM technologies
          WHERE category IS NOT NULL AND category != ''
          ON CONFLICT (name) DO NOTHING
        SQL

        add_column :technologies, :category_id, :bigint

        execute <<~SQL
          UPDATE technologies
          SET category_id = categories.id
          FROM categories
          WHERE technologies.category = categories.name
            AND technologies.category IS NOT NULL
            AND technologies.category != ''
        SQL

        add_foreign_key :technologies, :categories, column: :category_id
        remove_column :technologies, :category, :string
        add_index :technologies, :category_id
      end

      dir.down do
        remove_index :technologies, :category_id
        add_column :technologies, :category, :string

        execute <<~SQL
          UPDATE technologies
          SET category = categories.name
          FROM categories
          WHERE technologies.category_id = categories.id
        SQL

        remove_foreign_key :technologies, column: :category_id
        remove_column :technologies, :category_id
      end
    end
  end
end
