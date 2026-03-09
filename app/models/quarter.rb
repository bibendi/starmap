# Quarter model for Starmap application
# Represents quarterly cycles for skill evaluations and planning
class Quarter < ApplicationRecord
  # Associations
  belongs_to :previous_quarter, class_name: "Quarter", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  has_many :skill_ratings, dependent: :destroy
  has_many :users, through: :skill_ratings
  has_many :technologies, through: :skill_ratings
  has_many :action_plans, dependent: :destroy

  # Enum
  enum :status, {
    draft: "draft",
    active: "active",
    closed: "closed",
    archived: "archived"
  }, default: "draft"

  # Validations
  validates :name, presence: true, uniqueness: {scope: [:year]}
  validates :year, presence: true, numericality: {only_integer: true, greater_than: 2000}
  validates :quarter_number, presence: true, inclusion: {in: [1, 2, 3, 4]}
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :evaluation_start_date, presence: true
  validates :evaluation_end_date, presence: true
  validates :status, presence: true, inclusion: {in: %w[draft active closed archived]}

  # Validate date consistency
  validate :validate_date_sequence
  validate :validate_evaluation_dates

  # Callbacks
  before_validation :set_quarter_name, on: :create
  before_validation :calculate_evaluation_dates, on: :create
  after_create :set_as_current_if_first
  before_update :unset_current_if_needed
  after_update :handle_status_change

  # Scopes
  scope :ordered, -> { order(:year, :quarter_number) }
  scope :current, -> { where(is_current: true) }
  scope :active, -> { where(status: "active") }
  scope :closed, -> { where(status: "closed") }
  scope :archived, -> { where(status: "archived") }
  scope :draft, -> { where(status: "draft") }
  scope :by_year, ->(year) { where(year: year) }
  scope :recent, ->(limit = 10) { ordered.limit(limit) }
  scope :evaluable, -> { where(status: %w[active]) }

  # Helper methods
  def full_name
    "#{year} Q#{quarter_number}"
  end

  def human_name
    "#{quarter_number}й квартал #{year} года"
  end

  def current?
    is_current == true
  end

  def active?
    status == "active"
  end

  def closed?
    status == "closed"
  end

  def archived?
    status == "archived"
  end

  def draft?
    status == "draft"
  end

  def evaluation_period?
    Date.current.between?(evaluation_start_date, evaluation_end_date)
  end

  def within_quarter_period?
    Date.current.between?(start_date, end_date)
  end

  def past_quarter?
    end_date < Date.current
  end

  def future_quarter?
    start_date > Date.current
  end

  # Date helpers
  def days_remaining
    return 0 if Date.current > end_date
    (end_date - Date.current).to_i
  end

  def evaluation_days_remaining
    return 0 if Date.current > evaluation_end_date
    (evaluation_end_date - Date.current).to_i
  end

  def evaluation_progress_percentage
    total_days = (evaluation_end_date - evaluation_start_date).to_i
    return 100 if total_days <= 0
    return 0 if Date.current < evaluation_start_date
    return 100 if Date.current > evaluation_end_date

    completed_days = (Date.current - evaluation_start_date).to_i
    [(completed_days.to_f / total_days * 100).round(2), 100].min
  end

  # Skill ratings management
  def copy_previous_ratings(from_quarter = nil)
    from_quarter ||= previous_quarter
    return false if from_quarter.blank?

    copied_count = 0
    from_quarter.skill_ratings.each do |old_rating|
      next if skill_ratings.exists?(user: old_rating.user, technology: old_rating.technology)

      skill_ratings.create!(
        user: old_rating.user,
        technology: old_rating.technology,
        rating: old_rating.rating,
        comment: "Скопировано из #{from_quarter.full_name}",
        status: "draft",
        created_by: created_by
      )
      copied_count += 1
    end
    copied_count
  end

  def total_skill_ratings
    skill_ratings.count
  end

  def completed_skill_ratings
    skill_ratings.where(status: "approved").count
  end

  def draft_skill_ratings
    skill_ratings.where(status: "draft").count
  end

  def rating_completion_percentage
    return 0 if total_skill_ratings.zero?
    (completed_skill_ratings.to_f / total_skill_ratings * 100).round(2)
  end

  # Quarter navigation
  def next_quarter
    Quarter.where("(year > ? OR (year = ? AND quarter_number > ?))", year, year, quarter_number)
      .ordered.first
  end

  def previous_quarter
    Quarter.where("(year < ? OR (year = ? AND quarter_number < ?))", year, year, quarter_number)
      .ordered.last
  end

  def self.current
    find_by(is_current: true)
  end

  def self.find_or_create_current
    current || create_current_quarter
  end

  def self.create_current_quarter
    current_date = Date.current
    year = current_date.year

    # Calculate current quarter
    quarter_number = ((current_date.month - 1) / 3) + 1

    # Calculate quarter dates
    start_date = Date.new(year, (quarter_number - 1) * 3 + 1, 1)
    end_date = start_date.end_of_quarter

    # Evaluation period (2 weeks in the middle of quarter)
    evaluation_start_date = start_date + 45.days
    evaluation_end_date = evaluation_start_date + 14.days

    # Find previous quarter
    if quarter_number > 1
      Quarter.find_by(year: year, quarter_number: quarter_number - 1)
    else
      Quarter.find_by(year: year - 1, quarter_number: 4)
    end

    create!(
      year: year,
      quarter_number: quarter_number,
      start_date: start_date,
      end_date: end_date,
      evaluation_start_date: evaluation_start_date,
      evaluation_end_date: evaluation_end_date,
      status: "active",
      is_current: true,
      description: "Автоматически созданный квартал #{year} Q#{quarter_number}"
    )
  end

  # Analytics for dashboards
  def team_maturity_data
    # Returns maturity data grouped by teams
    data = {}
    Team.active.each do |team|
      team_ratings = skill_ratings.joins(user: :team).where(users: {team: team})
      total_ratings = team_ratings.count
      next if total_ratings.zero?

      high_skills = team_ratings.where(rating: 3).count
      data[team] = {
        maturity_index: (high_skills.to_f / total_ratings * 100).round(2),
        total_ratings: total_ratings,
        high_skills: high_skills
      }
    end
    data
  end

  def technology_risk_data
    # Returns risk data for all technologies
    Technology.active.map do |tech|
      tech_ratings = skill_ratings.where(technology: tech)
      total_ratings = tech_ratings.count
      next if total_ratings.zero?

      experts = tech_ratings.where(rating: 2..3).count
      {
        technology: tech,
        total_ratings: total_ratings,
        expert_count: experts,
        target_experts: tech.target_experts,
        risk_level: (experts < tech.target_experts) ? "medium" : "low",
        maturity_index: (tech_ratings.where(rating: 3).count.to_f / total_ratings * 100).round(2)
      }
    end.compact
  end

  def coverage_index_data
    # Returns coverage index data
    total_users = User.active.count
    return 0 if total_users.zero?

    rated_users = skill_ratings.joins(:user).where(users: {active: true}).distinct.count
    (rated_users.to_f / total_users * 100).round(2)
  end

  # Permission helpers
  def can_be_managed_by?(user)
    user.admin?
  end

  def can_be_viewed_by?(user)
    user.admin? || user.unit_lead? || user.team_lead?
  end

  def can_initiate_copy_from_previous?
    draft? && previous_quarter.present?
  end

  # Class methods for management
  def self.close_old_quarters
    # Close quarters that are more than 4 quarters old
    old_quarters = Quarter.where("end_date < ?", 1.year.ago).where.not(status: "archived")
    old_quarters.each do |quarter|
      quarter.update!(status: "archived")
    end
  end

  def self.activate_current_quarter
    current_quarter = find_or_create_current
    # Deactivate other current quarters
    Quarter.where(is_current: true).where.not(id: current_quarter.id).update_all(is_current: false)
    current_quarter
  end

  private

  def validate_date_sequence
    return unless start_date.present? && end_date.present?

    errors.add(:end_date, "должна быть позже даты начала") if end_date <= start_date
    errors.add(:evaluation_start_date, "должна быть в периоде квартала") if evaluation_start_date < start_date || evaluation_start_date > end_date
    errors.add(:evaluation_end_date, "должна быть в периоде квартала") if evaluation_end_date < start_date || evaluation_end_date > end_date
    errors.add(:evaluation_end_date, "должна быть позже даты начала оценки") if evaluation_end_date <= evaluation_start_date
  end

  def validate_evaluation_dates
    return unless evaluation_start_date.present? && evaluation_end_date.present?

    if evaluation_end_date - evaluation_start_date > 30.days
      errors.add(:evaluation_end_date, "период оценки не должен превышать 30 дней")
    end
  end

  def set_quarter_name
    self.name ||= full_name
  end

  def calculate_evaluation_dates
    return if evaluation_start_date.present? && evaluation_end_date.present?

    # Default evaluation period: middle 2 weeks of quarter
    quarter_midpoint = start_date + ((end_date - start_date) / 2).days
    self.evaluation_start_date = quarter_midpoint - 7.days
    self.evaluation_end_date = quarter_midpoint + 7.days
  end

  def set_as_current_if_first
    update!(is_current: true) if Quarter.count == 1
  end

  def unset_current_if_needed
    return unless is_current_changed? && is_current == false

    # If this was the current quarter and we're deactivating it,
    # try to set the next quarter as current
    next_q = next_quarter
    next_q&.update!(is_current: true) if next_q&.active?
  end

  def handle_status_change
    return unless status_changed?

    if status == "closed"
      # Lock all skill ratings when quarter is closed
      skill_ratings.where(status: %w[draft submitted]).update_all(status: "approved", locked: true)
    elsif status == "draft"
      # Unlock skill ratings when returning to draft
      skill_ratings.update_all(locked: false)
    end
  end
end
