# frozen_string_literal: true

class TeamMemberMetricsQuery
  METRIC_TYPES = [:competence_level, :universality, :expertise_concentration].freeze
  CRITICALITY_LEVELS = [:total, :high, :normal, :low].freeze

  def initialize(team:, user_ids:, assessment_period: AssessmentPeriod.current)
    @team = team
    @user_ids = user_ids
    @assessment_period = assessment_period
  end

  def metrics
    return {} if @assessment_period.nil? || @user_ids.empty?

    previous_assessment_period = @assessment_period.previous_assessment_period
    assessment_period_ids = [@assessment_period.id, previous_assessment_period&.id].compact

    ratings_by_assessment_period = load_ratings_for_assessment_periods(assessment_period_ids)

    current_ratings = ratings_by_assessment_period[@assessment_period.id] || []
    previous_ratings = previous_assessment_period ? ratings_by_assessment_period[previous_assessment_period.id] || [] : []

    current_metrics = calculate_metrics_for_ratings(current_ratings)
    previous_metrics = previous_assessment_period ? calculate_metrics_for_ratings(previous_ratings) : {}

    add_changes(current_metrics, previous_metrics)

    current_metrics
  end

  private

  def load_ratings_for_assessment_periods(assessment_period_ids)
    return {} if assessment_period_ids.empty?

    assessment_periods = [@assessment_period, @assessment_period.previous_assessment_period].compact

    ratings = SkillRating
      .joins(:technology)
      .joins("LEFT JOIN team_technologies ON team_technologies.team_id = skill_ratings.team_id AND team_technologies.technology_id = skill_ratings.technology_id")
      .visible_for_assessment_periods(assessment_periods)
      .where(team_id: @team.id, assessment_period_id: assessment_period_ids, technologies: {active: true})
      .select(
        "skill_ratings.*",
        "COALESCE(team_technologies.criticality, technologies.criticality) as effective_criticality"
      )

    ratings.group_by(&:assessment_period_id)
  end

  def initialize_metrics
    @user_ids.each_with_object({}) do |user_id, metrics|
      metrics[user_id] = METRIC_TYPES.each_with_object({}) do |metric_type, user_metrics|
        user_metrics[metric_type] = CRITICALITY_LEVELS.each_with_object({}) do |criticality, values|
          values[criticality] = 0
        end
      end
    end
  end

  def calculate_metrics_for_ratings(ratings)
    metrics = initialize_metrics
    return metrics if ratings.empty?

    experts_by_tech = calculate_experts_by_technology(ratings)

    ratings.each do |rating|
      process_rating(rating, metrics, experts_by_tech)
    end

    metrics
  end

  def calculate_experts_by_technology(ratings)
    ratings
      .select { |rating| rating.rating >= SkillRating::EXPERT_MIN_RATING }
      .group_by(&:technology_id)
      .transform_values { |tech_ratings| tech_ratings.map(&:user_id).uniq.count }
  end

  def process_rating(rating, metrics, experts_by_tech)
    user_id = rating.user_id
    return unless metrics.key?(user_id)

    criticality = (rating.effective_criticality || "normal").to_sym
    user_metrics = metrics[user_id]

    user_metrics[:competence_level][:total] += rating.rating
    user_metrics[:competence_level][criticality] += rating.rating

    if rating.rating > 1
      user_metrics[:universality][:total] += 1
      user_metrics[:universality][criticality] += 1
    end

    if rating.rating >= SkillRating::EXPERT_MIN_RATING && experts_by_tech[rating.technology_id] == 1
      user_metrics[:expertise_concentration][:total] += 1
      user_metrics[:expertise_concentration][criticality] += 1
    end
  end

  def add_changes(current_metrics, previous_metrics)
    return if previous_metrics.empty?

    current_metrics.each do |user_id, user_data|
      prev_data = previous_metrics[user_id]
      next unless prev_data

      METRIC_TYPES.each do |metric_type|
        CRITICALITY_LEVELS.each do |criticality|
          current_value = user_data[metric_type][criticality]
          previous_value = prev_data[metric_type][criticality]
          user_data[metric_type][:"#{criticality}_change"] = current_value - previous_value
        end
      end
    end
  end
end
