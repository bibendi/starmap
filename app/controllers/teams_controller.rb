class TeamsController < ApplicationController
  include ExpertConstants

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
