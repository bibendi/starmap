# frozen_string_literal: true

class TeamSkillMatrixComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :team, :team_skill_matrix, :team_members, :technologies, :bus_factor, :rating_dynamics

  def initialize(team:)
    @team = team
    @current_quarter = Quarter.current
    @team_members = @team&.users || []
    @technologies = team_technologies
    build_data
  end

  def any_data?
    return false unless @team_members.any?

    @team_skill_matrix.values.any? { |user_ratings| user_ratings.values.any?(&:positive?) }
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
    @technologies_by_id ||= @technologies.to_h { |t| [t.id, t] }
    @technologies_by_id[technology_id]
  end

  private

  def build_data
    @team_skill_matrix = build_team_skill_matrix
    @bus_factor = calculate_bus_factor
    @rating_dynamics = calculate_rating_dynamics
  end

  def team_technologies
    return [] unless @team

    @team.technologies
  end

  def team_technology_link_for(technology)
    @team_technologies_by_id ||= @team.team_technologies.to_h { |tt| [tt.technology_id, tt] }
    @team_technologies_by_id[technology.id]
  end

  def expert_counts_by_technology_and_quarter
    @expert_counts_by_technology_and_quarter ||= begin
      quarters = [@current_quarter]
      quarters << @current_quarter.previous_quarter if @current_quarter.previous_quarter

      SkillRating
        .where(
          quarter: quarters,
          rating: EXPERT_MIN_RATING..EXPERT_MAX_RATING,
          team_id: @team.id,
          technology_id: @technologies.map(&:id)
        )
        .group(:technology_id, :quarter_id)
        .count
        .each_with_object({}) { |((tech_id, quarter_id), count), hash|
          hash[tech_id] ||= {}
          hash[tech_id][quarter_id] = count
        }
    end
  end

  def expert_count_for(technology)
    expert_counts_by_technology_and_quarter.dig(technology.id, @current_quarter.id) || 0
  end

  def expert_count_for_quarter(technology, quarter)
    expert_counts_by_technology_and_quarter.dig(technology.id, quarter.id) || 0
  end

  def calculate_bus_factor
    previous_quarter = @current_quarter&.previous_quarter

    team_technologies.each_with_object({}) do |tech, bus_factors|
      team_tech = team_technology_link_for(tech)
      expert_count = expert_count_for(tech)
      target_experts = team_tech&.target_experts || 0

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

    ratings = load_skill_ratings
    fill_missing_ratings(ratings)
    sort_ratings_by_technology(ratings)
  end

  def load_skill_ratings
    SkillRating
      .where(
        quarter: @current_quarter,
        team_id: @team.id,
        technology_id: @technologies.map(&:id),
        user_id: @team_members.map(&:id)
      )
      .pluck(:technology_id, :user_id, :rating)
      .each_with_object({}) { |(tech_id, user_id, rating), hash|
        hash[tech_id] ||= {}
        hash[tech_id][user_id] = rating
      }
  end

  def fill_missing_ratings(ratings)
    @technologies.each do |tech|
      ratings[tech.id] ||= {}
      @team_members.each do |user|
        ratings[tech.id][user.id] ||= 0
      end
    end
    ratings
  end

  def sort_ratings_by_technology(ratings)
    @technologies.sort_by(&:name).each_with_object({}) do |tech, sorted|
      sorted[tech.id] = ratings[tech.id]
    end
  end

  def calculate_rating_dynamics
    return {} unless @current_quarter
    previous_quarter = @current_quarter.previous_quarter
    return {} unless previous_quarter

    ratings_by_tech_user = load_ratings_by_quarter(previous_quarter)
    calculate_differences(ratings_by_tech_user, previous_quarter)
  end

  def load_ratings_by_quarter(previous_quarter)
    ratings = SkillRating
      .where(
        quarter: [@current_quarter, previous_quarter],
        team_id: @team.id,
        technology_id: @technologies.map(&:id),
        user_id: @team_members.map(&:id)
      )
      .pluck(:technology_id, :user_id, :quarter_id, :rating)

    ratings.each_with_object({}) do |(tech_id, user_id, quarter_id, rating), hash|
      hash[tech_id] ||= {}
      hash[tech_id][user_id] ||= {}
      hash[tech_id][user_id][quarter_id] = rating
    end
  end

  def calculate_differences(ratings_by_tech_user, previous_quarter)
    dynamics = {}
    @technologies.each do |tech|
      @team_members.each do |user|
        current_rating = ratings_by_tech_user.dig(tech.id, user.id, @current_quarter.id) || 0
        previous_rating = ratings_by_tech_user.dig(tech.id, user.id, previous_quarter.id) || 0

        change = current_rating - previous_rating
        next if change == 0

        dynamics[tech.id] ||= {}
        dynamics[tech.id][user.id] = change
      end
    end
    dynamics
  end
end
