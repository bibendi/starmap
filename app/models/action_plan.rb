# ActionPlan model for Starmap application
# Represents action plans for skills development and risk mitigation
class ActionPlan < ApplicationRecord
  # Associations
  belongs_to :user, optional: true
  belongs_to :technology, optional: true
  belongs_to :quarter, optional: true
  belongs_to :created_by, class_name: 'User'
  belongs_to :assigned_to, class_name: 'User', optional: true

  # Validations
  validates :title, presence: true
  validates :status, presence: true, inclusion: { in: %w[active in_progress completed cancelled postponed] }
  validates :priority, presence: true, inclusion: { in: %w[low medium high critical] }

  # Validate that either user or technology is present
  validate :validate_target_presence
  validate :validate_dates_logic

  # Callbacks
  before_validation :set_default_priority, on: :create
  before_update :set_completed_at, if: :status_changed?
  after_update :handle_status_change

  # Scopes
  scope :active, -> { where(status: %w[active in_progress]) }
  scope :completed, -> { where(status: 'completed') }
  scope :cancelled, -> { where(status: 'cancelled') }
  scope :postponed, -> { where(status: 'postponed') }
  scope :high_priority, -> { where(priority: %w[high critical]) }
  scope :overdue, -> { where('due_date < ? AND status IN (?)', Date.current, %w[active in_progress]) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_technology, ->(technology) { where(technology: technology) }
  scope :by_quarter, ->(quarter) { where(quarter: quarter) }
  scope :by_assigned_to, ->(user) { where(assigned_to: user) }
  scope :by_created_by, ->(user) { where(created_by: user) }

  # Priority helpers
  def priority_label
    case priority
    when 'low' then 'Низкий'
    when 'medium' then 'Средний'
    when 'high' then 'Высокий'
    when 'critical' then 'Критический'
    else priority
    end
  end

  def critical_priority?
    priority == 'critical'
  end

  def high_priority?
    priority == 'high'
  end

  def medium_priority?
    priority == 'medium'
  end

  def low_priority?
    priority == 'low'
  end

  # Status helpers
  def active?
    status == 'active'
  end

  def in_progress?
    status == 'in_progress'
  end

  def completed?
    status == 'completed'
  end

  def cancelled?
    status == 'cancelled'
  end

  def postponed?
    status == 'postponed'
  end

  def can_be_started?
    active?
  end

  def can_be_completed?
    in_progress? || active?
  end

  def can_be_cancelled?
    active? || in_progress?
  end

  def can_be_postponed?
    active? || in_progress?
  end

  # Date helpers
  def due_soon?
    return false unless due_date.present?
    due_date <= 7.days.from_now.to_date && !completed?
  end

  def overdue?
    return false unless due_date.present?
    due_date < Date.current && !completed?
  end

  def days_until_due
    return nil unless due_date.present?
    (due_date - Date.current).to_i
  end

  def completion_timeframe
    return nil unless created_at.present?
    return 'Не установлен' unless due_date.present?

    days = (due_date - created_at.to_date).to_i
    case days
    when 0 then 'Сегодня'
    when 1 then '1 день'
    when 2..7 then "#{days} дней"
    when 8..30 then "Около месяца"
    when 31..90 then "Около 3 месяцев"
    else "Более 3 месяцев"
    end
  end

  # Progress tracking
  def start_progress
    update!(status: 'in_progress') if active?
  end

  def complete_plan(completion_notes = nil)
    update!(
      status: 'completed',
      progress_percentage: 100,
      completed_at: Date.current,
      completion_notes: completion_notes
    )
  end

  def cancel_plan(reason = nil)
    update!(
      status: 'cancelled',
      completion_notes: [completion_notes, "Отменено: #{reason}"].compact.join("\n")
    )
  end

  def postpone_plan(reason = nil)
    update!(
      status: 'postponed',
      completion_notes: [completion_notes, "Отложено: #{reason}"].compact.join("\n")
    )
  end

  def update_progress(percentage)
    percentage = [0, [percentage, 100].min].max
    update!(progress_percentage: percentage)

    # Auto-complete if 100%
    complete_plan if percentage == 100
  end

  # Target analysis
  def has_user_target?
    user_id.present?
  end

  def has_technology_target?
    technology_id.present?
  end

  def target_description
    if has_user_target? && has_technology_target?
      "#{user.display_name_or_full_name} - #{technology.name}"
    elsif has_user_target?
      user.display_name_or_full_name
    elsif has_technology_target?
      technology.name
    else
      'Общий план'
    end
  end

  # Risk context
  def risk_context
    return nil unless technology.present?

    # Determine if this plan addresses a known risk
    experts = technology.current_experts
    expert_count = experts.count
    target_experts = technology.target_experts

    if expert_count == 0
      {
        type: 'no_experts',
        severity: 'critical',
        description: 'Нет экспертов по технологии',
        recommendation: 'Критически необходимо обучить специалистов'
      }
    elsif expert_count == 1
      {
        type: 'single_expert',
        severity: 'high',
        description: 'Только один эксперт (риск ключевой фигуры)',
        recommendation: 'Необходимо обучить дополнительных специалистов',
        expert_name: experts.first.display_name_or_full_name
      }
    elsif expert_count < target_experts
      {
        type: 'insufficient_experts',
        severity: 'medium',
        description: "Недостаточно экспертов (#{expert_count}/#{target_experts})",
        recommendation: "Рекомендуется обучить #{target_experts - expert_count} дополнительных специалистов"
      }
    else
      {
        type: 'adequate_coverage',
        severity: 'low',
        description: "Достаточно экспертов (#{expert_count}/#{target_experts})",
        recommendation: 'Поддержание текущего уровня'
      }
    end
  end

  # Team context
  def team_context
    return nil unless user.present? && user.team.present?

    {
      team: user.team,
      team_name: user.team.name,
      team_lead: user.team.team_lead,
      member_count: user.team.member_count
    }
  end

  # Analytics helpers
  def self.overdue_plans_summary
    {
      total_overdue: overdue.count,
      by_priority: {
        critical: overdue.where(priority: 'critical').count,
        high: overdue.where(priority: 'high').count,
        medium: overdue.where(priority: 'medium').count,
        low: overdue.where(priority: 'low').count
      },
      by_technology: overdue.joins(:technology).group('technologies.name').count
    }
  end

  def self.completion_statistics(timeframe = 30.days)
    recent_plans = where('created_at >= ?', timeframe.ago)
    total = recent_plans.count
    completed = recent_plans.completed.count
    cancelled = recent_plans.cancelled.count

    {
      total: total,
      completed: completed,
      cancelled: cancelled,
      completion_rate: total > 0 ? (completed.to_f / total * 100).round(2) : 0,
      cancellation_rate: total > 0 ? (cancelled.to_f / total * 100).round(2) : 0
    }
  end

  def self.risk_mitigation_plans
    # Plans that are addressing identified risks
    joins(:technology).where(technologies: { criticality: 'high' }).active
  end

  # Permission helpers
  def can_be_viewed_by?(user)
    return true if user.admin?
    return user == created_by if created_by.present?
    return user == assigned_to if assigned_to.present?
    return user == user if user_id.present? && user == self.user
    return user.team_lead_of?(user.team) if user_id.present? && user.team_lead?
    false
  end

  def can_be_edited_by?(user)
    return true if user.admin?
    return user == created_by if created_by.present?
    return user == assigned_to if assigned_to.present?
    return user == user if user_id.present? && user == self.user
    false
  end

  def can_be_managed_by?(user)
    user.admin? || user.unit_lead?
  end

  # Class methods for management
  def self.create_for_technology_risks(quarter = nil)
    quarter ||= Quarter.current
    created_count = 0

    Technology.active.high_criticality.each do |tech|
      next if tech.has_sufficient_experts?(quarter)

      # Create plan to address the risk
      create!(
        title: "Развитие экспертизы по #{tech.name}",
        description: "План развития компетенций для снижения риска по технологии #{tech.name}. Текущее количество экспертов: #{tech.expert_count(quarter)}, целевое: #{tech.target_experts}.",
        technology: tech,
        quarter: quarter,
        status: 'active',
        priority: tech.criticality == 'high' ? 'high' : 'medium',
        due_date: quarter.end_date,
        created_by: User.admins.first || User.first
      )
      created_count += 1
    end
    created_count
  end

  def self.create_for_user_development(user, target_technologies, quarter = nil)
    quarter ||= Quarter.current
    created_count = 0

    target_technologies.each do |tech|
      create!(
        title: "Развитие навыков по #{tech.name}",
        description: "План развития компетенций для #{user.display_name_or_full_name} по технологии #{tech.name}.",
        user: user,
        technology: tech,
        quarter: quarter,
        status: 'active',
        priority: 'medium',
        due_date: quarter.end_date,
        created_by: user.team_lead || User.admins.first || User.first,
        assigned_to: user
      )
      created_count += 1
    end
    created_count
  end

  private

  def validate_target_presence
    return if user_id.present? || technology_id.present?
    errors.add(:base, 'План должен быть привязан к пользователю или технологии')
  end

  def validate_dates_logic
    return unless due_date.present? && completed_at.present?
    errors.add(:due_date, 'должна быть позже даты создания') if due_date < created_at.to_date
    errors.add(:completed_at, 'должна быть позже даты создания') if completed_at < created_at.to_date
    errors.add(:completed_at, 'должна быть не раньше планируемой даты завершения') if completed_at > due_date && due_date.present?
  end

  def set_default_priority
    self.priority ||= 'medium'
  end

  def set_completed_at
    return unless status == 'completed'
    self.completed_at ||= Date.current
    self.progress_percentage = 100
  end

  def handle_status_change
    return unless status_changed?

    case status
    when 'in_progress'
      # Could trigger notifications
    when 'completed'
      # Could trigger notifications or celebrations
    when 'cancelled'
      # Could trigger notifications about cancellation
    when 'postponed'
      # Could trigger notifications about postponement
    end
  end
end
