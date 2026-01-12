# Technology model for Starmap application
# Represents technologies with criticality levels and target expert counts
class Technology < ApplicationRecord
  # Associations
  belongs_to :created_by, class_name: 'User', optional: true
  belongs_to :updated_by, class_name: 'User', optional: true
  has_many :skill_ratings, dependent: :destroy
  has_many :users, through: :skill_ratings
  has_many :action_plans, dependent: :destroy
  has_many :team_technologies, dependent: :destroy
  has_many :teams, through: :team_technologies

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :criticality, presence: true, inclusion: { in: %w[high normal low] }
  validates :target_experts, numericality: { only_integer: true, greater_than: 0 }
  validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :set_default_values, on: :create
  before_update :set_updated_by, if: :saved_changes?

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_criticality, ->(criticality) { where(criticality: criticality) }
  scope :high_criticality, -> { where(criticality: 'high') }
  scope :ordered, -> { order(:sort_order, :name) }

  # Criticality helpers
  def criticality_label
    case criticality
    when 'high' then 'Высокая'
    when 'normal' then 'Обычная'
    when 'low' then 'Низкая'
    else criticality
    end
  end

  def high_criticality?
    criticality == 'high'
  end

  def normal_criticality?
    criticality == 'normal'
  end

  def low_criticality?
    criticality == 'low'
  end

  # Expert analysis
  def current_experts(quarter = nil, team = nil)
    quarter ||= Quarter.current
    query = User.joins(:skill_ratings)
      .where(skill_ratings: { technology: self, quarter: quarter, rating: 2..3 })
      .distinct
    query = query.where(skill_ratings: { team_id: team.id }) if team
    query
  end

  def expert_count(quarter = nil, team = nil)
    current_experts(quarter, team).count
  end

  def has_sufficient_experts?(quarter = nil, team = nil)
    target = team ? target_experts_for(team) : target_experts
    expert_count(quarter, team) >= target
  end

  def expert_deficit(quarter = nil, team = nil)
    target = team ? target_experts_for(team) : target_experts
    [0, target - expert_count(quarter, team)].max
  end

  def is_critical_risk?(quarter = nil, team = nil)
    criticality_level = team ? criticality_for(team) : criticality
    target = team ? target_experts_for(team) : target_experts
    criticality_level == 'high' && expert_count(quarter, team) < target
  end

  # Team-specific helpers
  def target_experts_for(team)
    team_tech = team_technologies.find_by(team_id: team.id)
    team_tech&.target_experts || target_experts
  end

  def criticality_for(team)
    team_tech = team_technologies.find_by(team_id: team.id)
    team_tech&.criticality || criticality
  end

  def bus_factor_risk_for(team, quarter = nil)
    quarter ||= Quarter.current
    team_tech = team_technologies.find_by(team_id: team.id)
    target = team_tech&.target_experts || target_experts
    experts = current_experts(quarter, team)

    if experts.count == 0
      {
        level: 'high',
        description: 'Нет экспертов',
        experts: [],
        recommendation: 'Необходимо обучить специалиста'
      }
    elsif experts.count < target
      {
        level: 'medium',
        description: "Недостаточно экспертов (#{experts.count}/#{target})",
        experts: experts,
        recommendation: "Рекомендуется обучить #{expert_deficit(quarter, team)} дополнительных специалистов"
      }
    else
      {
        level: 'low',
        description: "Достаточно экспертов (#{experts.count}/#{target})",
        experts: experts,
        recommendation: 'Уровень риска низкий'
      }
    end
  end

  # Skill rating distribution
  def skill_distribution(quarter = nil)
    quarter ||= Quarter.current
    distribution = { 0 => 0, 1 => 0, 2 => 0, 3 => 0 }

    skill_ratings.joins(:user).where(quarter: quarter, users: { active: true }).each do |rating|
      distribution[rating.rating] += 1
    end

    distribution
  end

  def average_skill_level(quarter = nil)
    quarter ||= Quarter.current
    ratings = skill_ratings.joins(:user).where(quarter: quarter, users: { active: true })
    return 0 if ratings.empty?

    ratings.average(:rating).to_f.round(2)
  end

  def maturity_index(quarter = nil)
    quarter ||= Quarter.current
    total_ratings = skill_ratings.joins(:user).where(quarter: quarter, users: { active: true }).count
    return 0 if total_ratings.zero?

    high_skills = skill_ratings.joins(:user).where(quarter: quarter, users: { active: true }, rating: 3).count
    (high_skills.to_f / total_ratings * 100).round(2)
  end

  # Coverage analysis
  def coverage_percentage(quarter = nil)
    quarter ||= Quarter.current
    total_users = User.active.count
    return 0 if total_users.zero?

    rated_users = skill_ratings.joins(:user).where(quarter: quarter, users: { active: true }).distinct.count
    (rated_users.to_f / total_users * 100).round(2)
  end

  def coverage_index(quarter = nil)
    quarter ||= Quarter.current
    # Coverage Index = (users with rating >= 1) / total users * 100
    coverage_percentage(quarter)
  end

  # Risk assessment
  def bus_factor_risk(quarter = nil)
    quarter ||= Quarter.current
    experts = current_experts(quarter)

    if experts.count == 0
      {
        level: 'high',
        description: 'Нет экспертов',
        experts: [],
        recommendation: 'Необходимо обучить специалиста'
      }
    elsif experts.count < target_experts
      {
        level: 'medium',
        description: "Недостаточно экспертов (#{experts.count}/#{target_experts})",
        experts: experts,
        recommendation: "Рекомендуется обучить #{expert_deficit(quarter)} дополнительных специалистов"
      }
    else
      {
        level: 'low',
        description: "Достаточно экспертов (#{experts.count}/#{target_experts})",
        experts: experts,
        recommendation: 'Уровень риска низкий'
      }
    end
  end

  # Trend analysis
  def skill_trend(quarters = 4)
    # Returns skill level changes over last N quarters
    quarter_ids = Quarter.ordered.where('start_date <= ?', Date.current).last(quarters).pluck(:id)
    trend_data = []

    quarter_ids.each do |quarter_id|
      quarter = Quarter.find(quarter_id)
      trend_data << {
        quarter: quarter.name,
        average_level: average_skill_level(quarter),
        expert_count: expert_count(quarter),
        coverage: coverage_percentage(quarter)
      }
    end

    trend_data
  end

  # Action plans
  def active_action_plans
    action_plans.where(status: %w[in_progress pending])
  end

  def completed_action_plans
    action_plans.where(status: 'completed')
  end

  def action_plan_progress
    plans = action_plans
    return { total: 0, completed: 0, percentage: 0 } if plans.empty?

    completed = plans.where(status: 'completed').count
    {
      total: plans.count,
      completed: completed,
      percentage: (completed.to_f / plans.count * 100).round(2)
    }
  end

  # Permission helpers
  def can_be_managed_by?(user)
    user.admin?
  end

  def can_be_viewed_by?(user)
    user.admin? || user.unit_lead? || user.team_lead?
  end

  # Class methods for analytics
  def self.critical_technologies_risk(quarter = nil)
    quarter ||= Quarter.current
    high_criticality.map do |tech|
      {
        technology: tech,
        risk: tech.bus_factor_risk(quarter),
        priority: tech.criticality
      }
    end.select { |item| item[:risk][:level] != 'low' }
  end

  def self.coverage_gaps(quarter = nil)
    quarter ||= Quarter.current
    active.map do |tech|
      next if tech.has_sufficient_experts?(quarter)

      {
        technology: tech,
        current_experts: tech.expert_count(quarter),
        target_experts: tech.target_experts,
        deficit: tech.expert_deficit(quarter)
      }
    end.compact
  end

  def self.maturity_leaders(limit = 10)
    active.map do |tech|
      {
        technology: tech,
        maturity_index: tech.maturity_index,
        average_level: tech.average_skill_level
      }
    end.sort_by { |item| -item[:maturity_index] }.first(limit)
  end

  private

  def set_default_values
    self.criticality ||= 'normal'
    self.target_experts ||= 2
    self.sort_order ||= Technology.maximum(:sort_order).to_i + 1
  end

  def set_updated_by
    # This would be set by the controller, but we can have a fallback
    self.updated_by_id ||= User.first&.id
  end
end
