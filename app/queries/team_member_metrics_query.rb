# frozen_string_literal: true

class TeamMemberMetricsQuery
  METRIC_TYPES = [:competence_level, :universality, :expertise_concentration].freeze
  CRITICALITY_LEVELS = [:total, :high, :normal, :low].freeze

  def initialize(team:, user_ids:, quarter: Quarter.current)
    @team = team
    @user_ids = user_ids
    @quarter = quarter
  end

  def metrics
    return {} if @quarter.nil? || @user_ids.empty?

    previous_quarter = @quarter.previous_quarter
    quarter_ids = [@quarter.id, previous_quarter&.id].compact

    ratings_by_quarter = load_ratings_for_quarters(quarter_ids)

    current_ratings = ratings_by_quarter[@quarter.id] || []
    previous_ratings = previous_quarter ? ratings_by_quarter[previous_quarter.id] || [] : []

    current_metrics = calculate_metrics_for_ratings(current_ratings)
    previous_metrics = previous_quarter ? calculate_metrics_for_ratings(previous_ratings) : {}

    add_changes(current_metrics, previous_metrics)

    current_metrics
  end

  private

  def load_ratings_for_quarters(quarter_ids)
    return {} if quarter_ids.empty?

    quarters = [@quarter, @quarter.previous_quarter].compact

    ratings = SkillRating
      .joins(:technology)
      .joins("LEFT JOIN team_technologies ON team_technologies.team_id = skill_ratings.team_id AND team_technologies.technology_id = skill_ratings.technology_id")
      .visible_for_quarters(quarters)
      .where(team_id: @team.id, quarter_id: quarter_ids, technologies: {active: true})
      .select(
        "skill_ratings.*",
        "COALESCE(team_technologies.criticality, technologies.criticality) as effective_criticality"
      )

    ratings.group_by(&:quarter_id)
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
