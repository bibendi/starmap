# frozen_string_literal: true

class AssessmentPeriodsTool < McpBaseTool
  tool_name "assessment_periods"
  description "Returns the complete assessment period catalogue, including all types and statuses, in chronological order."

  input_schema(properties: {})

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  def self.execute(server_context:)
    authorize(server_context[:current_identity], AssessmentPeriod, :index)
    text_response({periods: AssessmentPeriod.ordered.map { |period| period_metadata(period) }}.to_json)
  end

  def self.period_metadata(period)
    {
      id: period.id,
      name: period.full_name,
      period_kind: period.period_kind,
      status: period.status,
      start_date: period.start_date.iso8601,
      end_date: period.end_date.iso8601,
      evaluation_start_date: period.evaluation_start_date.iso8601,
      evaluation_end_date: period.evaluation_end_date.iso8601,
      is_current: period.is_current?
    }
  end
  private_class_method :period_metadata
end
