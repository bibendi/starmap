# frozen_string_literal: true

class TeamMemberMetricsComponent < ViewComponent::Base
  include ExpertConstants

  attr_reader :team, :team_member_metrics, :team_members

  def initialize(team:)
    @team = team
    @current_quarter = Quarter.current
    @team_members = @team ? @team.users : []
    @team_member_metrics = calculate_team_member_metrics
  end

  def any_data?
    return false unless @team_members.any?

    @team_member_metrics.values.any? do |metrics|
      metrics.values.any? do |metric|
        metric.values.any?(&:positive?)
      end
    end
  end

  private

  def calculate_team_member_metrics
    previous_quarter = @current_quarter.previous_quarter
    quarter_ids = [@current_quarter.id, previous_quarter&.id].compact

    ratings_by_quarter = load_ratings_for_quarters(quarter_ids)

    current_ratings = ratings_by_quarter[@current_quarter.id] || []
    previous_ratings = previous_quarter ? ratings_by_quarter[previous_quarter.id] || [] : []

    current_metrics = calculate_metrics_for_ratings(current_ratings)
    previous_metrics = previous_quarter ? calculate_metrics_for_ratings(previous_ratings) : {}

    add_changes(current_metrics, previous_metrics)

    current_metrics
  end

  def load_ratings_for_quarters(quarter_ids)
    return {} if quarter_ids.empty?

    ratings = SkillRating
      .joins(:technology)
      .joins("LEFT JOIN team_technologies ON team_technologies.team_id = skill_ratings.team_id AND team_technologies.technology_id = skill_ratings.technology_id")
      .where(team_id: @team.id, quarter_id: quarter_ids, technologies: { active: true })
      .select(
        'skill_ratings.*',
        'COALESCE(team_technologies.criticality, technologies.criticality) as effective_criticality'
      )

    ratings.group_by(&:quarter_id)
  end

  def calculate_metrics_for_ratings(ratings)
    metrics = initialize_metrics

    return metrics if ratings.empty?

    experts_by_tech = ratings
      .select { |r| r.rating >= EXPERT_MIN_RATING }
      .group_by(&:technology_id)
      .transform_values { |tech_ratings| tech_ratings.map(&:user_id).uniq.count }

    ratings.each do |rating|
      user_id = rating.user_id
      next unless metrics.key?(user_id)

      criticality = rating.effective_criticality || 'normal'
      user_metrics = metrics[user_id]

      user_metrics[:competence_level][:total] += rating.rating
      user_metrics[:competence_level][criticality.to_sym] += rating.rating

      if rating.rating > 1
        user_metrics[:universality][:total] += 1
        user_metrics[:universality][criticality.to_sym] += 1
      end

      if rating.rating >= EXPERT_MIN_RATING && experts_by_tech[rating.technology_id] == 1
        user_metrics[:expertise_concentration][:total] += 1
        user_metrics[:expertise_concentration][criticality.to_sym] += 1
      end
    end

    metrics
  end

  def initialize_metrics
    metrics = {}
    @team_members.each do |user|
      metrics[user.id] = {
        competence_level: { total: 0, high: 0, normal: 0, low: 0 },
        universality: { total: 0, high: 0, normal: 0, low: 0 },
        expertise_concentration: { total: 0, high: 0, normal: 0, low: 0 }
      }
    end
    metrics
  end

  def add_changes(current_metrics, previous_metrics)
    return if previous_metrics.empty?

    current_metrics.each do |user_id, user_data|
      prev_data = previous_metrics[user_id]
      next unless prev_data

      [:competence_level, :universality, :expertise_concentration].each do |metric_type|
        [:total, :high, :normal, :low].each do |criticality|
          current_value = user_data[metric_type][criticality]
          previous_value = prev_data[metric_type][criticality]
          user_data[metric_type]["#{criticality}_change".to_sym] = current_value - previous_value
        end
      end
    end
  end
end
