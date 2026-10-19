require "rails_helper"
require_relative "../../db/migrate/20261018210000_generalize_assessment_periods"

RSpec.describe GeneralizeAssessmentPeriods do
  let(:connection) { ActiveRecord::Base.connection }
  let(:migration) { described_class.new }

  around do |example|
    connection.execute("CREATE SCHEMA period_migration_test")
    old_path = connection.schema_search_path
    connection.schema_search_path = "period_migration_test"
    connection.execute(<<~SQL)
      CREATE TABLE quarters (id bigserial PRIMARY KEY, name text NOT NULL, year integer NOT NULL,
        quarter_number integer NOT NULL, start_date date NOT NULL, end_date date NOT NULL,
        evaluation_start_date date, evaluation_end_date date, status text NOT NULL DEFAULT 'active',
        is_current boolean NOT NULL DEFAULT false, created_by_id bigint, description text,
        created_at timestamp, updated_at timestamp);
      CREATE UNIQUE INDEX index_quarters_on_year_and_quarter_number ON quarters(year, quarter_number);
      CREATE UNIQUE INDEX index_quarters_on_name_and_year ON quarters(name, year);
      CREATE TABLE skill_ratings (id bigint PRIMARY KEY, quarter_id bigint NOT NULL REFERENCES quarters(id), rating integer);
      CREATE TABLE action_plans (id bigint PRIMARY KEY, quarter_id bigint REFERENCES quarters(id));
      INSERT INTO quarters VALUES (17, 'Original', 2026, 1, '2026-01-01', '2026-03-31',
        '2026-04-01', '2026-04-15', 'closed', true, 42, 'Preserved', NOW(), NOW());
      INSERT INTO skill_ratings VALUES (1, 17, 3);
      INSERT INTO action_plans VALUES (2, 17);
    SQL
    ActiveRecord::Migration.suppress_messages { example.run }
  ensure
    connection.schema_search_path = old_path
    connection.execute("DROP SCHEMA period_migration_test CASCADE")
    connection.schema_cache.clear!
  end

  it "preserves values and both references and reverses without losing history" do
    original = connection.select_all("SELECT * FROM quarters").to_a
    migration.migrate(:up)
    expect(connection.select_value("SELECT period_kind FROM assessment_periods")).to eq("quarterly")
    expect(connection.select_value("SELECT assessment_period_id FROM skill_ratings")).to eq(17)
    expect(connection.select_value("SELECT assessment_period_id FROM action_plans")).to eq(17)
    expect(connection.select_value("SELECT rating FROM skill_ratings")).to eq(3)
    migration.migrate(:down)
    expect(connection.select_all("SELECT * FROM quarters").to_a).to eq(original)
    expect(connection.select_value("SELECT quarter_id FROM action_plans")).to eq(17)
  end

  it "rejects overlap directly in PostgreSQL and permits an adjacent period" do
    migration.migrate(:up)
    connection.execute(<<~SQL)
      INSERT INTO assessment_periods (name, start_date, end_date, evaluation_start_date, evaluation_end_date)
      VALUES ('Q2', '2026-04-01', '2026-06-30', '2026-07-01', '2026-07-15')
    SQL
    expect do
      connection.transaction(requires_new: true) do
        connection.execute(<<~SQL)
          INSERT INTO assessment_periods (name, start_date, end_date, evaluation_start_date, evaluation_end_date)
          VALUES ('Overlap', '2026-03-31', '2026-06-30', '2026-07-01', '2026-07-15')
        SQL
      end
    end.to raise_error(ActiveRecord::StatementInvalid, /assessment_periods_no_overlap/)
    expect(connection.select_value("SELECT COUNT(*) FROM assessment_periods")).to eq(2)
  end

  it "refuses rollback for nonquarterly data before changing the schema" do
    migration.migrate(:up)
    connection.execute("UPDATE assessment_periods SET period_kind = 'custom'")
    expect { migration.migrate(:down) }.to raise_error(ActiveRecord::IrreversibleMigration)
    expect(connection.select_value("SELECT period_kind FROM assessment_periods")).to eq("custom")
  end

  it "refuses invalid source data without changing it" do
    connection.execute("UPDATE quarters SET evaluation_start_date = NULL")
    expect { migration.migrate(:up) }.to raise_error(AssessmentPeriodMigrationPreflight::InvalidData, /17/)
    expect(connection.select_value("SELECT COUNT(*) FROM quarters")).to eq(1)
  end

  it "enforces one active and one current and valid date/type fields" do
    migration.migrate(:up)
    connection.execute(<<~SQL)
      INSERT INTO assessment_periods (name, start_date, end_date, evaluation_start_date, evaluation_end_date, status)
      VALUES ('Q2', '2026-04-01', '2026-06-30', '2026-07-01', '2026-07-15', 'active')
    SQL
    ["is_current = true", "status = 'active'", "period_kind = 'invalid'", "evaluation_end_date = evaluation_start_date"].each do |assignment|
      predicate = assignment.start_with?("status") ? "id = 17" : "id <> 17"
      expect do
        connection.transaction(requires_new: true) { connection.execute("UPDATE assessment_periods SET #{assignment} WHERE #{predicate}") }
      end.to raise_error(ActiveRecord::StatementInvalid)
    end
  end
end
