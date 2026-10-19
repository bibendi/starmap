require "rails_helper"

RSpec.describe AssessmentPeriodMigrationPreflight do
  let(:connection) { ActiveRecord::Base.connection }
  let(:checker) { described_class.new(connection) }

  around do |example|
    connection.execute("CREATE SCHEMA period_preflight_test")
    connection.execute("SET LOCAL search_path TO period_preflight_test, public")
    connection.execute(<<~SQL)
      CREATE TABLE period_preflight_test.quarters (
        id bigint, year integer, quarter_number integer, start_date date, end_date date,
        evaluation_start_date date, evaluation_end_date date, status text, is_current boolean)
    SQL
    %w[skill_ratings action_plans].each do |table|
      connection.execute("CREATE TABLE period_preflight_test.#{table} (id bigint, quarter_id bigint)")
    end
    example.run
  ensure
    connection.execute("SET LOCAL search_path TO public")
    connection.execute("DROP SCHEMA period_preflight_test CASCADE")
  end

  def insert_quarter(id:, start_date: "2026-01-01", end_date: "2026-03-31", number: 1)
    connection.execute(<<~SQL)
      INSERT INTO quarters (id, year, quarter_number, start_date, end_date,
        evaluation_start_date, evaluation_end_date, status, is_current)
      VALUES (#{id}, 2026, #{number}, '#{start_date}', '#{end_date}',
        '2026-10-01', '2026-10-15', 'closed', false)
    SQL
  end

  it "accepts valid quarters and does not mutate them" do
    insert_quarter(id: 1)
    before = connection.select_all("SELECT * FROM quarters").to_a
    expect(checker.validate!).to be true
    expect(connection.select_all("SELECT * FROM quarters").to_a).to eq(before)
  end

  it "reports overlapping ids and invalid calendar boundaries" do
    insert_quarter(id: 1)
    insert_quarter(id: 2, start_date: "2026-03-31", end_date: "2026-06-30", number: 2)
    expect(checker.errors).to include("Overlapping quarters: 1, 2", "Quarter 2: invalid calendar or evaluation dates")
  end

  it "reports duplicate current and active selections and missing references" do
    insert_quarter(id: 1)
    insert_quarter(id: 2, start_date: "2026-04-01", end_date: "2026-06-30", number: 2)
    connection.execute("UPDATE quarters SET is_current = true, status = 'active'")
    connection.execute("INSERT INTO action_plans (id, quarter_id) VALUES (9, 999)")
    expect(checker.errors.join("\n")).to include("Multiple is_current=true", "Multiple status=active", "action_plans 9: missing quarter")
    expect { checker.validate! }.to raise_error(described_class::InvalidData)
  end
end
