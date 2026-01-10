class TeamsController < ApplicationController
  before_action :authenticate_user!

  # Skip policy scope verification as we use explicit authorization
  skip_after_action :verify_policy_scoped

  def show
    # Find team by name parameter or use current user's team
    if params[:name].present?
      @team = Team.find_by!(name: params[:name])
    else
      @team = current_user.team || Team.new
    end

    # Authorize access to the team
    authorize @team

    @current_quarter = Quarter.current
    @team_members = @team&.users || []
    @technologies = Technology.includes(:skill_ratings)
      .where(skill_ratings: { quarter: Quarter.current })
      .order(:name)

    # Calculate team metrics
    @team_skill_matrix = build_team_skill_matrix
    @competency_dynamics = calculate_competency_dynamics
    @universality_index = calculate_universality_index
    @key_person_risks = identify_key_person_risks
  end

  private

  def build_team_skill_matrix
    # Creates team skill matrix
    team_users = @team&.users || []
    technologies = Technology.includes(:skill_ratings)
      .where(skill_ratings: { quarter: Quarter.current })
      .order(:name)

    matrix = {}
    technologies.each do |tech|
      matrix[tech.id] = {}
      team_users.each do |user|
        rating = user.skill_ratings.find_by(technology: tech, quarter: Quarter.current)&.rating || 0
        matrix[tech.id][user.id] = rating
      end
    end
    matrix
  end

  def calculate_competency_dynamics
    # Competency dynamics for the quarter
    current_quarter = Quarter.current
    previous_quarter = current_quarter.previous_quarter

    return {} unless previous_quarter

    team_users = @team&.users || []
    dynamics = {}

    team_users.each do |user|
      current_ratings = user.skill_ratings.where(quarter: current_quarter).index_by(&:technology_id)
      previous_ratings = user.skill_ratings.where(quarter: previous_quarter).index_by(&:technology_id)

      total_change = 0
      current_ratings.each do |tech_id, current_rating|
        previous_rating = previous_ratings[tech_id]&.rating || 0
        total_change += (current_rating.rating - previous_rating)
      end

      dynamics[user.id] = total_change
    end

    dynamics
  end

  def calculate_universality_index
    # Universality index = number of technologies with level >= 2
    current_quarter = Quarter.current
    team_users = @team&.users || []
    universality = {}

    team_users.each do |user|
      count = user.skill_ratings.where(quarter: current_quarter, rating: 2..3).count
      universality[user.id] = count
    end

    universality
  end

  def identify_key_person_risks
    # Key Person Risk = technologies where employee is the only expert
    team_users = @team&.users || []
    technologies = Technology.includes(:skill_ratings)
      .where(skill_ratings: { quarter: Quarter.current })
    risks = {}

    technologies.each do |tech|
      experts = tech.skill_ratings.where(quarter: Quarter.current, rating: 2..3).pluck(:user_id)
      if experts.size == 1
        risks[tech.id] = experts.first
      end
    end

    risks
  end
end
