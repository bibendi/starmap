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

    # Preload technologies for skill matrix to avoid N+1 queries
    @technologies = Technology.includes(:skill_ratings)
      .where(skill_ratings: { quarter: Quarter.current })
      .order(:name)

    # Calculate team metrics
    @team_skill_matrix = build_team_skill_matrix
    @competency_dynamics = calculate_competency_dynamics
    @universality_index = calculate_universality_index
    @key_person_risks = identify_key_person_risks
    @coverage_index = calculate_coverage_index
    @maturity_index = calculate_maturity_index
    @red_zones = identify_red_zones

    # Preload users for key person risks to avoid N+1 queries
    @key_person_risk_users = User.where(id: @key_person_risks.values).index_by(&:id) if @key_person_risks.any?

    # Technology counts by criticality
    @technology_counts = technology_counts_by_criticality
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

  def calculate_coverage_index
    current_quarter = Quarter.current
    technologies = Technology.includes(:skill_ratings)
      .where(skill_ratings: { quarter: current_quarter })

    return 0 if technologies.empty?

    covered_count = technologies.count do |tech|
      experts = tech.skill_ratings.where(quarter: current_quarter, rating: 2..3).count
      experts >= 2
    end

    ((covered_count.to_f / technologies.count) * 100).round
  end

  def calculate_maturity_index
    current_quarter = Quarter.current
    team_users = @team&.users || []

    ratings = SkillRating.where(user: team_users, quarter: current_quarter)
    return 0 if ratings.empty?

    (ratings.average(:rating)&.round(1) || 0)
  end

  def identify_red_zones
    current_quarter = Quarter.current
    technologies = Technology.includes(:skill_ratings)
      .where(criticality: :high)
      .where(skill_ratings: { quarter: current_quarter })

    red_zones = {}
    technologies.each do |tech|
      experts = tech.skill_ratings.where(quarter: current_quarter, rating: 2..3).count
      red_zones[tech.id] = experts
    end

    red_zones
  end

  def technology_counts_by_criticality
    current_quarter = Quarter.current
    counts = { high: 0, medium: 0, low: 0 }

    Technology.joins(:skill_ratings)
      .where(skill_ratings: { quarter: current_quarter })
      .distinct
      .pluck(:criticality)
      .each do |criticality|
        counts[criticality.to_sym] += 1 if counts.key?(criticality.to_sym)
      end

    counts
  end
end
