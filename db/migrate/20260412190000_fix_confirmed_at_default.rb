class FixConfirmedAtDefault < ActiveRecord::Migration[8.1]
  def up
    change_column_default :users, :confirmed_at, from: false, to: nil
    execute <<-SQL
      ALTER TABLE users ALTER COLUMN confirmed_at TYPE timestamp USING
        CASE WHEN confirmed_at IS TRUE THEN NOW() ELSE NULL END;
    SQL
  end

  def down
    execute <<-SQL
      ALTER TABLE users ALTER COLUMN confirmed_at TYPE boolean USING
        CASE WHEN confirmed_at IS NOT NULL THEN TRUE ELSE FALSE END;
    SQL
    change_column_default :users, :confirmed_at, to: false, from: nil
  end
end
