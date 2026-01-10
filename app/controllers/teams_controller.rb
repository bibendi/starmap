class TeamsController < ApplicationController
  include ExpertConstants

  before_action :authenticate_user!
  before_action :set_team, :set_team_context

  # Skip policy scope verification as we use explicit authorization
  skip_after_action :verify_policy_scoped

  def show
    # Preload technologies for skill matrix
    @technologies = team_technologies.order(:name)

    # Calculate team metrics
    @team_skill_matrix = build_team_skill_matrix
    @competency_dynamics = calculate_competency_dynamics
    @universality_index = calculate_universality_index
    @key_person_risks = identify_key_person_risks
    @coverage_index = calculate_coverage_index
    @maturity_index = calculate_maturity_index
    @red_zones = identify_red_zones
    @technology_counts = technology_counts_by_criticality

    # Preload users for key person risks to avoid N+1 queries
    @key_person_risk_users = User.where(id: @key_person_risks.values).index_by(&:id) if @key_person_risks.any?

    # Preload all technologies referenced in metrics for view (avoid N+1)
    all_tech_ids = (@red_zones.keys + @key_person_risks.keys).uniq
    @technologies_index = if all_tech_ids.any?
                            Technology.where(id: all_tech_ids).index_by(&:id)
                          else
                            {}
                          end
  end

  private

  # Callbacks to set up team context
  def set_team
    @team = if params[:name].present?
              Team.find_by!(name: params[:name])
            else
              current_user.team || Team.new
            end
    authorize @team
  end

  def set_team_context
    @current_quarter = Quarter.current
    @team_members = @team&.users || []
    @team_member_ids = @team_members.map(&:id)
  end

  # Helper methods to reduce duplication
  def team_technologies
    Technology.joins(:skill_ratings)
      .where(skill_ratings: { quarter: @current_quarter, user_id: @team_member_ids })
      .distinct
  end

  def high_criticality_technologies
    Technology.where(criticality: :high, active: true)
  end

  def expert_count_for(technology)
    technology.skill_ratings
      .where(quarter: @current_quarter, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, user_id: @team_member_ids)
      .count
  end

  # Main metric calculation methods
  def build_team_skill_matrix
    team_technologies.each_with_object({}) do |tech, matrix|
      matrix[tech.id] = {}
      @team_members.each do |user|
        rating = user.skill_ratings.find_by(technology: tech, quarter: @current_quarter)&.rating || 0
        matrix[tech.id][user.id] = rating
      end
    end
  end

  def calculate_competency_dynamics
    previous_quarter = @current_quarter.previous_quarter
    return {} unless previous_quarter

    dynamics = {}
    @team_members.each do |user|
      current_ratings = user.skill_ratings.where(quarter: @current_quarter).index_by(&:technology_id)
      previous_ratings = user.skill_ratings.where(quarter: previous_quarter).index_by(&:technology_id)

      total_change = current_ratings.sum do |tech_id, current_rating|
        previous_rating = previous_ratings[tech_id]&.rating || 0
        current_rating.rating - previous_rating
      end

      dynamics[user.id] = total_change
    end
    dynamics
  end

  def calculate_universality_index
    @team_members.each_with_object({}) do |user, hash|
      hash[user.id] = user.skill_ratings.where(quarter: @current_quarter, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING).count
    end
  end

  def identify_key_person_risks
    risks = {}
    team_technologies.each do |tech|
      experts = tech.skill_ratings
        .where(quarter: @current_quarter, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, user_id: @team_member_ids)
        .pluck(:user_id)

      risks[tech.id] = experts.first if experts.size == SINGLE_EXPERT_THRESHOLD
    end
    risks
  end

  def calculate_coverage_index
    technologies = team_technologies
    return 0 if technologies.empty?

    covered_count = technologies.count { |tech| expert_count_for(tech) >= MIN_EXPERTS_FOR_COVERAGE }
    ((covered_count.to_f / technologies.count) * 100).round
  end

  def calculate_maturity_index
    ratings = SkillRating.where(user_id: @team_member_ids, quarter: @current_quarter)
    ratings.average(:rating)&.round(1) || 0
  end

  def identify_red_zones
    # Only include high and normal criticality technologies with insufficient experts (< 2)
    team_technologies.where(criticality: [:normal, :high]).each_with_object({}) do |tech, hash|
      expert_count = expert_count_for(tech)
      hash[tech.id] = expert_count if expert_count < MIN_EXPERTS_FOR_COVERAGE
    end
  end

  def technology_counts_by_criticality
    team_technologies
      .group(:criticality)
      .count
      .transform_keys(&:to_sym)
      .then { |counts| { high: counts[:high] || 0, normal: counts[:normal] || 0, low: counts[:low] || 0 } }
  end
end
