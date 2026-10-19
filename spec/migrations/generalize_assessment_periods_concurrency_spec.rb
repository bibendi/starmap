require "rails_helper"
require_relative "../../db/migrate/20261018210000_generalize_assessment_periods"

RSpec.describe GeneralizeAssessmentPeriods do
  self.use_transactional_tests = false

  let(:connection) { ActiveRecord::Base.connection }

  around do |example|
    old_path = connection.schema_search_path
    connection.execute("CREATE SCHEMA period_concurrency_test")
    connection.schema_search_path = "period_concurrency_test"
    ActiveRecord::Migration.suppress_messages { load Rails.root.join("db/schema.rb") }
    example.run
  ensure
    connection.schema_search_path = old_path
    connection.execute("DROP SCHEMA period_concurrency_test CASCADE")
    connection.schema_cache.clear!
  end

  def concurrent_inserts(second_start:, second_end:, selection: "")
    config = ActiveRecord::Base.connection_db_config.configuration_hash
    credentials = {host: config[:host], port: config[:port], user: config[:username], password: config[:password], dbname: config[:database]}
    ready = Queue.new
    proceed = Queue.new
    results = Queue.new
    threads = [["2030-01-01", "2030-03-31"], [second_start, second_end]].map do |start_date, end_date|
      Thread.new do
        client = PG.connect(credentials)
        client.exec("SET search_path TO period_concurrency_test")
        ready << true
        proceed.pop
        begin
          client.exec(<<~SQL)
            INSERT INTO assessment_periods
              (name, start_date, end_date, evaluation_start_date, evaluation_end_date, created_at, updated_at #{", #{selection}" unless selection.empty?})
            VALUES ('Concurrent', '#{start_date}', '#{end_date}', '2031-01-01', '2031-01-15', NOW(), NOW() #{((selection == "status") ? ", 'active'" : ", true") unless selection.empty?})
          SQL
          results << :saved
        rescue PG::ExclusionViolation, PG::UniqueViolation
          results << :conflict
        ensure
          client.close
        end
      end
    end
    2.times { ready.pop }
    2.times { proceed << true }
    threads.each(&:value)
    2.times.map { results.pop }
  end

  it "rejects one of two concurrent overlapping creations" do
    expect(concurrent_inserts(second_start: "2030-03-01", second_end: "2030-06-30")).to contain_exactly(:saved, :conflict)
    expect(connection.select_value("SELECT COUNT(*) FROM assessment_periods")).to eq(1)
  end

  %w[status is_current].each do |selection|
    it "preserves a single #{selection} selection under concurrent writes" do
      expect(concurrent_inserts(second_start: "2030-04-01", second_end: "2030-06-30", selection: selection)).to contain_exactly(:saved, :conflict)
    end
  end
end
