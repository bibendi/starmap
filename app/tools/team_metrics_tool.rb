# frozen_string_literal: true

class TeamMetricsTool < McpBaseTool
  tool_name "team_metrics"
  description "Returns competency health metrics for a team: coverage index, maturity index, red zones count, and key person risks count."

  input_schema(
    properties: {
      team_name: {type: "string", description: "The name of the team to query metrics for"},
      quarter: {type: "string", description: "Quarter identifier in format 'YYYY QN' (e.g. '2026 Q1'). Defaults to the current active quarter."}
    },
    required: ["team_name"]
  )

  annotations(
    read_only_hint: true,
    destructive_hint: false,
    idempotent_hint: true,
    open_world_hint: false
  )

  def self.execute(team_name:, server_context:, quarter: nil)
    current_identity = server_context[:current_identity]

    team = Team.find_by(name: team_name)
    not_found!("Team '#{team_name}' not found") unless team
    authorize current_identity, team

    resolved_quarter = resolve_quarter(quarter)
    unless resolved_quarter
      message = quarter ? "Quarter '#{quarter}' not found" : "No active quarter found. Specify a quarter parameter."
      not_found!(message)
    end

    text_response calculate_metrics(team, resolved_quarter).to_json
  end

  def self.resolve_quarter(quarter_param)
    return Quarter.current if quarter_param.blank?

    year, q = quarter_param.match(/^(\d{4})\s+Q(\d)$/)&.captures
    return nil unless year && q

    Quarter.find_by(year: year.to_i, quarter_number: q.to_i)
  end
  private_class_method :resolve_quarter

  def self.calculate_metrics(team, quarter)
    teams = [team]
    {
      team: team.name,
      quarter: quarter.full_name,
      coverage_index: CoverageIndexQuery.new(teams:, quarter:).percentage,
      maturity_index: MaturityIndexQuery.new(teams:, quarter:).value,
      red_zones_count: RedZonesQuery.new(teams:, quarter:).count,
      key_person_risks_count: KeyPersonRisksQuery.new(teams:, quarter:).count
    }
  end
  private_class_method :calculate_metrics
end
