# frozen_string_literal: true

class TeamSkillMatrixComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :team, :team_skill_matrix, :team_members, :technologies, :bus_factor, :rating_dynamics

  def initialize(team:)
    @team = team
    @current_quarter = Quarter.current
    @team_members = @team&.users || []
    @technologies = team_technologies
    @team_skill_matrix = build_team_skill_matrix
    @bus_factor = calculate_bus_factor
    @rating_dynamics = calculate_rating_dynamics
  end

  def any_data?
    return false unless @team_members.any?
    return false unless @team_skill_matrix.any?

    # Check if there's any non-zero rating
    @team_skill_matrix.values.any? { |user_ratings| user_ratings.values.any? { |r| r > 0 } }
  end

  def has_dynamics?
    @rating_dynamics.any?
  end

  def bus_factor_for(technology_id)
    @bus_factor[technology_id]
  end

  def rating_for(technology_id, user_id)
    @team_skill_matrix.dig(technology_id, user_id) || 0
  end

  def change_for(technology_id, user_id)
    @rating_dynamics.dig(technology_id, user_id)
  end

  def technology_for(technology_id)
    @technologies.find { |t| t.id == technology_id }
  end

  private

  def team_technologies
    @team.technologies.order(:name)
  end

  def team_technology_for(technology)
    @team.team_technologies.find_by(technology_id: technology.id)
  end

  def expert_count_for(technology)
    technology.skill_ratings
      .where(quarter: @current_quarter, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, team_id: @team.id)
      .count
  end

  def expert_count_for_quarter(technology, quarter)
    technology.skill_ratings
      .where(quarter: quarter, rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING, team_id: @team.id)
      .count
  end

  def calculate_bus_factor
    previous_quarter = @current_quarter&.previous_quarter

    team_technologies.each_with_object({}) do |tech, bus_factors|
      team_tech = team_technology_for(tech)
      expert_count = expert_count_for(tech)
      target_experts = team_tech.target_experts

      risk_level = if expert_count == 0
                     'high'
                   elsif expert_count < target_experts
                     'medium'
                   else
                     'low'
                   end

      bus_factor_data = {
        count: expert_count,
        target: target_experts,
        risk_level: risk_level,
        criticality: team_tech&.criticality || 'normal'
      }

      if previous_quarter
        previous_expert_count = expert_count_for_quarter(tech, previous_quarter)
        bus_factor_data[:previous_count] = previous_expert_count
        bus_factor_data[:change] = expert_count - previous_expert_count
      end

      bus_factors[tech.id] = bus_factor_data
    end
  end

  def build_team_skill_matrix
    return {} unless @current_quarter

    team_technologies.each_with_object({}) do |tech, matrix|
      matrix[tech.id] = {}
      @team_members.each do |user|
        rating = user.skill_ratings.find_by(technology: tech, quarter: @current_quarter)&.rating || 0
        matrix[tech.id][user.id] = rating
      end
    end
  end

  def calculate_rating_dynamics
    return {} unless @current_quarter
    previous_quarter = @current_quarter.previous_quarter
    return {} unless previous_quarter

    dynamics = {}

    team_technologies.each do |tech|
      @team_members.each do |user|
        current_rating = user.skill_ratings.find_by(technology: tech, quarter: @current_quarter, team_id: @team.id)&.rating || 0
        previous_rating = user.skill_ratings.find_by(technology: tech, quarter: previous_quarter, team_id: @team.id)&.rating || 0

        change = current_rating - previous_rating
        if change != 0
          dynamics[tech.id] ||= {}
          dynamics[tech.id][user.id] = change
        end
      end
    end

    dynamics
  end
end
