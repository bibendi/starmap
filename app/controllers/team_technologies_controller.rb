class TeamTechnologiesController < ApplicationController
  include ExpertConstants

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
    @skill_ratings = load_skill_ratings(@current_quarter)
    @previous_ratings = load_previous_ratings
    @team_technology = TeamTechnology.find_by(team: @team, technology: @technology)
    @expert_count = calculate_expert_count
    @previous_expert_count = calculate_previous_expert_count
    @bus_factor_risk_level = bus_factor_risk_level
    @bus_factor_change = @expert_count - @previous_expert_count
    @coverage = coverage_percentage
  end

  private

  def set_team_and_technology
    @team = Team.find(params[:team_id])
    @technology = Technology.find(params[:id])

    unless TeamTechnology.exists?(team_id: @team.id, technology_id: @technology.id)
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

  def load_skill_ratings(quarter)
    SkillRating
      .where(quarter: quarter, team_id: @team.id, technology_id: @technology.id, status: :approved)
      .pluck(:user_id, :rating)
      .to_h
  end

  def load_previous_ratings
    previous_quarter = @current_quarter.previous_quarter
    return {} unless previous_quarter

    SkillRating
      .where(quarter: previous_quarter, team_id: @team.id, technology_id: @technology.id, status: :approved)
      .pluck(:user_id, :rating)
      .to_h
  end

  def calculate_expert_count
    SkillRating
      .where(quarter: @current_quarter, team_id: @team.id, technology_id: @technology.id, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, status: :approved)
      .select(:user_id)
      .distinct
      .count
  end

  def calculate_previous_expert_count
    previous_quarter = @current_quarter.previous_quarter
    return 0 unless previous_quarter

    SkillRating
      .where(quarter: previous_quarter, team_id: @team.id, technology_id: @technology.id, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, status: :approved)
      .select(:user_id)
      .distinct
      .count
  end

  def bus_factor_risk_level
    target = @team_technology&.target_experts || 0
    return "high" if @expert_count == 0
    return "medium" if @expert_count < target
    "low"
  end

  def coverage_percentage
    total = @team_members.size
    return 0 if total.zero?

    [(@expert_count.to_f / total * 100).round, 100].min
  end
end
