class TeamsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team, :set_team_context, only: [:show]

  # Skip policy scope verification as we use explicit authorization
  skip_after_action :verify_policy_scoped

  def index
    @teams = policy_scope(Team).includes(:unit, :team_lead).ordered.page(params[:page]).per(20)
    authorize Team
  end

  def show
    @technologies = @team.technologies.order(:name)
    @technology_counts = technology_counts_by_criticality

    red_zones_query = RedZonesQuery.new(teams: [@team], quarter: @current_quarter)
    @red_zones_count = red_zones_query.count
    @red_zones_data = red_zones_query.details

    @coverage_index = CoverageIndexQuery.new(teams: [@team], quarter: @current_quarter).percentage
    @maturity_index = MaturityIndexQuery.new(teams: [@team], quarter: @current_quarter).value

    key_person_risks_query = KeyPersonRisksQuery.new(teams: [@team], quarter: @current_quarter)
    @key_person_risks_count = key_person_risks_query.count
    @key_person_risks_data = key_person_risks_query.details

    @competency_dynamics = CompetencyDynamicsQuery.new(
      team: @team, user_ids: @team_members.map(&:id), quarter: @current_quarter
    ).data

    @universality_index = UniversalityIndexQuery.new(team: @team, quarter: @current_quarter).data

    @team_member_metrics = TeamMemberMetricsQuery.new(
      team: @team, user_ids: @team_members.map(&:id), quarter: @current_quarter
    ).metrics

    skill_matrix_query = TeamSkillMatrixQuery.new(
      team: @team, technologies: @technologies, user_ids: @team_members.map(&:id), quarter: @current_quarter
    )
    @bus_factor = skill_matrix_query.bus_factor
    @skill_matrix = skill_matrix_query.skill_matrix
    @rating_dynamics = skill_matrix_query.rating_dynamics
  end

  private

  # Callbacks to set up team context
  def set_team
    @team = if params[:id].present?
      Team.find(params[:id])
    elsif current_user.team.present?
      current_user.team
    else
      redirect_to teams_path and return
    end
    authorize @team
  end

  def set_team_context
    @current_quarter = Quarter.current
    @team_members = sorted_team_members
  end

  def sorted_team_members
    return [] if @team.blank?

    members = @team.users.to_a
    team_lead = members.find { |u| u.id == @team.team_lead_id }
    other_members = members.reject { |u| u.id == @team.team_lead_id }
      .sort_by { |u| u.full_name.downcase }

    team_lead ? [team_lead] + other_members : other_members
  end

  def technology_counts_by_criticality
    @team.team_technologies
      .group(:criticality)
      .count
      .transform_keys(&:to_sym)
      .then { |counts| {high: counts[:high] || 0, normal: counts[:normal] || 0, low: counts[:low] || 0} }
  end
end
