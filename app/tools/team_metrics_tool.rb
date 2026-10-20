# frozen_string_literal: true

class TeamMetricsTool < McpBaseTool
  tool_name "team_metrics"
  description "Returns competency health metrics for a team: coverage index, maturity index, red zones count, and key person risks count."

  input_schema(
    properties: {
      team_name: {type: "string", description: "The name of the team to query metrics for"},
      period_id: {type: "integer", description: "Assessment period ID from assessment_periods. Defaults to the current assessment period."}
    },
    required: ["team_name"]
  )

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  def self.execute(team_name:, server_context:, period_id: nil)
    current_identity = server_context[:current_identity]

    team = Team.find_by(name: team_name)
    not_found!("Team '#{team_name}' not found") unless team
    authorize current_identity, team

    resolved_assessment_period = resolve_assessment_period(period_id)
    unless resolved_assessment_period
      message = period_id ? "Assessment period '#{period_id}' not found" : "No current assessment period found. Call assessment_periods to discover IDs, then specify period_id."
      not_found!(message)
    end

    text_response calculate_metrics(team, resolved_assessment_period).to_json
  end

  def self.resolve_assessment_period(period_id)
    return AssessmentPeriod.current if period_id.nil?
    return unless period_id.is_a?(Integer) && period_id.positive?

    AssessmentPeriod.find_by(id: period_id)
  end
  private_class_method :resolve_assessment_period

  def self.calculate_metrics(team, assessment_period)
    teams = [team]
    {
      team: team.name,
      period_id: assessment_period.id,
      period_name: assessment_period.full_name,
      coverage_index: CoverageIndexQuery.new(teams:, assessment_period:).percentage,
      maturity_index: MaturityIndexQuery.new(teams:, assessment_period:).value,
      red_zones_count: RedZonesQuery.new(teams:, assessment_period:).count,
      key_person_risks_count: KeyPersonRisksQuery.new(teams:, assessment_period:).count
    }
  end
  private_class_method :calculate_metrics
end
