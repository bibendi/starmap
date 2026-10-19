# frozen_string_literal: true

class TeamSkillMatrixQuery
  def initialize(team:, technologies:, user_ids:, assessment_period: AssessmentPeriod.current)
    @team = team
    @technologies = technologies
    @user_ids = user_ids
    @assessment_period = assessment_period
  end

  def bus_factor
    return {} if @assessment_period.nil?

    team_technologies_by_id = @team.team_technologies.active.index_by(&:technology_id)
    expert_counts = expert_counts_by_technology_and_assessment_period
    previous_assessment_period = @assessment_period.previous_assessment_period

    @technologies.each_with_object({}) do |tech, bus_factors|
      team_tech = team_technologies_by_id[tech.id]
      expert_count = expert_counts.dig(tech.id, @assessment_period.id) || 0
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

      if previous_assessment_period
        previous_expert_count = expert_counts.dig(tech.id, previous_assessment_period.id) || 0
        bus_factor_data[:previous_count] = previous_expert_count
        bus_factor_data[:change] = expert_count - previous_expert_count
      end

      bus_factors[tech.id] = bus_factor_data
    end
  end

  def raw_ratings
    return {} if @assessment_period.nil?

    SkillRating
      .visible_for_assessment_period(@assessment_period)
      .where(
        assessment_period: @assessment_period,
        team_id: @team.id,
        technology_id: @technologies.map(&:id),
        user_id: @user_ids
      )
      .pluck(:technology_id, :user_id, :rating)
      .each_with_object({}) { |(tech_id, user_id, rating), hash|
        hash[tech_id] ||= {}
        hash[tech_id][user_id] = rating
      }
  end

  def skill_matrix
    return {} if @assessment_period.nil?

    ratings = raw_ratings

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
    return {} if @assessment_period.nil?

    previous_assessment_period = @assessment_period.previous_assessment_period
    return {} unless previous_assessment_period

    ratings_by_tech_user = SkillRating
      .visible_for_assessment_periods([@assessment_period, previous_assessment_period])
      .where(
        assessment_period: [@assessment_period, previous_assessment_period],
        team_id: @team.id,
        technology_id: @technologies.map(&:id),
        user_id: @user_ids
      )
      .pluck(:technology_id, :user_id, :assessment_period_id, :rating)
      .each_with_object({}) do |(tech_id, user_id, assessment_period_id, rating), hash|
        hash[tech_id] ||= {}
        hash[tech_id][user_id] ||= {}
        hash[tech_id][user_id][assessment_period_id] = rating
      end

    dynamics = {}
    @technologies.each do |tech|
      @user_ids.each do |user_id|
        current_rating = ratings_by_tech_user.dig(tech.id, user_id, @assessment_period.id) || 0
        previous_rating = ratings_by_tech_user.dig(tech.id, user_id, previous_assessment_period.id) || 0

        change = current_rating - previous_rating
        next if change == 0

        dynamics[tech.id] ||= {}
        dynamics[tech.id][user_id] = change
      end
    end
    dynamics
  end

  private

  def expert_counts_by_technology_and_assessment_period
    assessment_periods = [@assessment_period]
    assessment_periods << @assessment_period.previous_assessment_period if @assessment_period.previous_assessment_period

    SkillRating
      .visible_for_assessment_periods(assessment_periods)
      .expert_ratings
      .where(
        assessment_period: assessment_periods,
        team_id: @team.id,
        technology_id: @technologies.map(&:id)
      )
      .group(:technology_id, :assessment_period_id)
      .count
      .each_with_object({}) { |((tech_id, assessment_period_id), count), hash|
        hash[tech_id] ||= {}
        hash[tech_id][assessment_period_id] = count
      }
  end
end
