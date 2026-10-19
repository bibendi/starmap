# frozen_string_literal: true

# Read-only data check run automatically by the assessment period migration.
class AssessmentPeriodMigrationPreflight
  class InvalidData < StandardError; end

  def initialize(connection)
    @connection = connection
  end

  def errors
    rows = @connection.select_all("SELECT * FROM quarters ORDER BY start_date, id").to_a
    date_errors(rows) + overlap_errors(rows) + selection_errors(rows) + reference_errors
  end

  def validate!
    problems = errors
    raise InvalidData, problems.join("\n") if problems.any?

    true
  end

  private

  def date_errors(rows)
    rows.filter_map do |row|
      next if valid_dates?(row)

      "Quarter #{row["id"]}: invalid calendar or evaluation dates"
    end
  end

  def valid_dates?(row)
    year, number = row.values_at("year", "quarter_number")
    return false unless year && year > 2000 && (1..4).cover?(number)

    start_date = Date.new(year, (number - 1) * 3 + 1, 1)
    finish, eval_start, eval_end = row.values_at("end_date", "evaluation_start_date", "evaluation_end_date")
    row["start_date"] == start_date && finish == start_date.end_of_quarter &&
      eval_start && eval_end && eval_start >= finish && eval_end > eval_start
  end

  def overlap_errors(rows)
    rows.combination(2).filter_map do |left, right|
      next unless left["start_date"] && left["end_date"] && right["start_date"] && right["end_date"]
      next unless left["start_date"] <= right["end_date"] && right["start_date"] <= left["end_date"]

      "Overlapping quarters: #{left["id"]}, #{right["id"]}"
    end
  end

  def selection_errors(rows)
    [[:is_current, true], [:status, "active"]].filter_map do |field, value|
      ids = rows.select { |row| row[field.to_s] == value }.pluck("id")
      "Multiple #{field}=#{value} quarters: #{ids.join(", ")}" if ids.size > 1
    end
  end

  def reference_errors
    %w[skill_ratings action_plans].flat_map do |table|
      @connection.select_values(<<~SQL).map { |id| "#{table} #{id}: missing quarter" }
        SELECT records.id FROM #{table} records
        LEFT JOIN quarters ON quarters.id = records.quarter_id
        WHERE records.quarter_id IS NOT NULL AND quarters.id IS NULL
      SQL
    end
  end
end
