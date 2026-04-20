class TeamTechnologiesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_team_and_technology

  skip_after_action :verify_policy_scoped

  def show
    @current_quarter = Quarter.current

    unless @current_quarter
      redirect_to team_path(@team), alert: t("team_technologies.show.no_active_quarter.message")
      return
    end

    @team_members = sorted_team_members
    @team_technology = TeamTechnology.find_by(team: @team, technology: @technology)

    query = TeamSkillMatrixQuery.new(
      team: @team,
      technologies: [@technology],
      user_ids: @team_members.map(&:id),
      quarter: @current_quarter
    )

    bus_factor = query.bus_factor[@technology.id]
    @expert_count = bus_factor[:count]
    @bus_factor_risk_level = bus_factor[:risk_level]
    @bus_factor_change = bus_factor[:change] || 0
    @skill_ratings = query.raw_ratings[@technology.id] || {}
    @rating_dynamics = query.rating_dynamics[@technology.id] || {}
    @coverage = coverage_percentage
  end

  private

  def set_team_and_technology
    @team = Team.find(params[:team_id])
    @technology = Technology.find(params[:id])

    unless TeamTechnology.active.exists?(team_id: @team.id, technology_id: @technology.id)
      raise ActiveRecord::RecordNotFound
    end

    authorize @team, policy_class: TeamTechnologyPolicy
  end

  def sorted_team_members
    members = @team.users.to_a
    team_lead = members.find { |u| u.id == @team.team_lead_id }
    other_members = members.reject { |u| u.id == @team.team_lead_id }
      .sort_by { |u| u.full_name.downcase }

    team_lead ? [team_lead] + other_members : other_members
  end

  def coverage_percentage
    total = @team_members.size
    return 0 if total.zero?

    [(@expert_count.to_f / total * 100).round, 100].min
  end
end
