class DashboardsController < ApplicationController
  before_action :authenticate_user!

  # Skip policy scope verification as dashboards don't return collections
  skip_after_action :verify_policy_scoped

  # Overview Dashboard - доступен всем аутентифицированным пользователям
  def overview
    authorize :dashboard, :overview?

    @current_quarter = Quarter.current
    @technologies = Technology.includes(:skill_ratings).where(skill_ratings: {quarter: Quarter.current}).order(:name)
    @teams = Team.includes(:users)

    # Метрики для Overview Dashboard
    @coverage_index = calculate_coverage_index
    @maturity_index = calculate_maturity_index
    @red_zones = identify_red_zones
  end

  # Personal Dashboard - доступен только владельцу
  def personal
    authorize :dashboard, :personal?

    @current_quarter = Quarter.current
    @user_skill_ratings = current_user.skill_ratings.includes(:technology, :quarter).where(quarter: Quarter.current)
    @technologies = Technology.includes(:skill_ratings).where(skill_ratings: {quarter: Quarter.current}).order(:name)

    # Метрики для Personal Dashboard
    @personal_growth = calculate_personal_growth
    @critical_expertise_index = calculate_critical_expertise_index
    @action_plans = current_user.action_plans.includes(:technology).active
  end

  private

  def calculate_coverage_index
    # Coverage Index = (количество технологий с >= 2 экспертами) / (общее количество технологий)
    total_technologies = Technology.count
    covered_technologies = Technology.joins(:skill_ratings)
      .where(skill_ratings: {rating: 2..3, quarter: Quarter.current})
      .group(:technology_id)
      .having("COUNT(*) >= 2")
      .count
    (covered_technologies.size.to_f / total_technologies * 100).round(1)
  end

  def calculate_maturity_index
    # Maturity Index = средняя оценка по всем технологиям
    SkillRating.current.average(:rating)&.round(1) || 0
  end

  def identify_red_zones
    # Red Zones = технологии с высокой критичностью и низким покрытием
    Technology.joins(:skill_ratings)
      .where(criticality: "high", skill_ratings: {quarter: Quarter.current})
      .group(:technology_id)
      .having("COUNT(CASE WHEN skill_ratings.rating >= 2 THEN 1 END) < 2")
      .count
  end

  def calculate_personal_growth
    # Личный рост за квартал
    current_quarter = Quarter.current
    previous_quarter = current_quarter.previous_quarter

    return {} unless previous_quarter

    current_ratings = current_user.skill_ratings.where(quarter: current_quarter).index_by(&:technology_id)
    previous_ratings = current_user.skill_ratings.where(quarter: previous_quarter).index_by(&:technology_id)

    growth = {}
    current_ratings.each do |tech_id, current_rating|
      previous_rating = previous_ratings[tech_id]&.rating || 0
      growth[tech_id] = current_rating.rating - previous_rating
    end

    growth
  end

  def calculate_critical_expertise_index
    # Индекс критической экспертизы
    critical_technologies = Technology.where(criticality: "high")
    critical_ratings = current_user.skill_ratings
      .where(technology: critical_technologies, quarter: Quarter.current, rating: 2..3)
      .count

    total_critical = critical_technologies.count
    (total_critical > 0) ? (critical_ratings.to_f / total_critical * 100).round(1) : 0
  end
end
