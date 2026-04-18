# frozen_string_literal: true

class TeamSkillMatrixQuery
  def initialize(team:, technologies:, user_ids:, quarter: Quarter.current)
    @team = team
    @technologies = technologies
    @user_ids = user_ids
    @quarter = quarter
  end

  def bus_factor
    return {} if @quarter.nil?

    team_technologies_by_id = @team.team_technologies.index_by(&:technology_id)
    expert_counts = expert_counts_by_technology_and_quarter
    previous_quarter = @quarter.previous_quarter

    @technologies.each_with_object({}) do |tech, bus_factors|
      team_tech = team_technologies_by_id[tech.id]
      expert_count = expert_counts.dig(tech.id, @quarter.id) || 0
      target_experts = team_tech&.target_experts || 0

      risk_level = if expert_count == 0
        "high"
      elsif expert_count < target_experts
        "medium"
      else
        "low"
      end

      bus_factor_data = {
        count: expert_count,
        target: target_experts,
        risk_level: risk_level,
        criticality: team_tech&.criticality || "normal"
      }

      if previous_quarter
        previous_expert_count = expert_counts.dig(tech.id, previous_quarter.id) || 0
        bus_factor_data[:previous_count] = previous_expert_count
        bus_factor_data[:change] = expert_count - previous_expert_count
      end

      bus_factors[tech.id] = bus_factor_data
    end
  end

  def skill_matrix
    return {} if @quarter.nil?

    ratings = SkillRating
      .visible_for_quarter(@quarter)
      .where(
        quarter: @quarter,
        team_id: @team.id,
        technology_id: @technologies.map(&:id),
        user_id: @user_ids
      )
      .pluck(:technology_id, :user_id, :rating)
      .each_with_object({}) { |(tech_id, user_id, rating), hash|
        hash[tech_id] ||= {}
        hash[tech_id][user_id] = rating
      }

    @technologies.each do |tech|
      ratings[tech.id] ||= {}
      @user_ids.each do |user_id|
        ratings[tech.id][user_id] ||= 0
      end
    end

    @technologies.sort_by(&:name).each_with_object({}) do |tech, sorted|
      sorted[tech.id] = ratings[tech.id]
    end
  end

  def rating_dynamics
    return {} if @quarter.nil?

    previous_quarter = @quarter.previous_quarter
    return {} unless previous_quarter

    ratings_by_tech_user = SkillRating
      .visible_for_quarters([@quarter, previous_quarter])
      .where(
        quarter: [@quarter, previous_quarter],
        team_id: @team.id,
        technology_id: @technologies.map(&:id),
        user_id: @user_ids
      )
      .pluck(:technology_id, :user_id, :quarter_id, :rating)
      .each_with_object({}) do |(tech_id, user_id, quarter_id, rating), hash|
        hash[tech_id] ||= {}
        hash[tech_id][user_id] ||= {}
        hash[tech_id][user_id][quarter_id] = rating
      end

    dynamics = {}
    @technologies.each do |tech|
      @user_ids.each do |user_id|
        current_rating = ratings_by_tech_user.dig(tech.id, user_id, @quarter.id) || 0
        previous_rating = ratings_by_tech_user.dig(tech.id, user_id, previous_quarter.id) || 0

        change = current_rating - previous_rating
        next if change == 0

        dynamics[tech.id] ||= {}
        dynamics[tech.id][user_id] = change
      end
    end
    dynamics
  end

  private

  def expert_counts_by_technology_and_quarter
    quarters = [@quarter]
    quarters << @quarter.previous_quarter if @quarter.previous_quarter

    SkillRating
      .visible_for_quarters(quarters)
      .expert_ratings
      .where(
        quarter: quarters,
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
