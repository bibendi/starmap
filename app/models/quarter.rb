class Quarter < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many :skill_ratings, dependent: :destroy
  has_many :users, through: :skill_ratings
  has_many :technologies, through: :skill_ratings
  has_many :action_plans, dependent: :destroy

  enum :status, {
    draft: "draft",
    active: "active",
    closed: "closed",
    archived: "archived"
  }, default: "draft"

  validates :name, presence: true, uniqueness: {scope: [:year]}
  validates :year, presence: true, numericality: {only_integer: true, greater_than: 2000}
  validates :quarter_number, presence: true, inclusion: {in: [1, 2, 3, 4]}
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :evaluation_start_date, presence: true
  validates :evaluation_end_date, presence: true
  validates :status, presence: true, inclusion: {in: %w[draft active closed archived]}
  validates :quarter_number, uniqueness: {scope: :year}

  validate :validate_year_is_current_or_future
  validate :validate_date_sequence
  validate :validate_evaluation_dates

  before_validation :set_quarter_name, on: :create
  after_create :set_as_current_if_first
  after_update :handle_status_change

  scope :ordered, -> { order(:year, :quarter_number) }

  def full_name
    "#{year} Q#{quarter_number}"
  end

  def evaluation_period?
    Date.current.between?(evaluation_start_date, evaluation_end_date)
  end

  def previous_quarter
    Quarter.where("(year < ? OR (year = ? AND quarter_number < ?))", year, year, quarter_number)
      .ordered.last
  end

  def self.current
    find_by(is_current: true)
  end

  private

  def validate_year_is_current_or_future
    return if year.blank?

    errors.add(:year, :current_or_future_only) if year < Date.current.year
  end

  def validate_date_sequence
    return unless start_date.present? && end_date.present?
    errors.add(:end_date, :after_start_date) if end_date <= start_date

    return unless evaluation_start_date.present? && evaluation_end_date.present?
    errors.add(:evaluation_start_date, :within_quarter) if evaluation_start_date < start_date || evaluation_start_date > end_date
    errors.add(:evaluation_end_date, :within_quarter) if evaluation_end_date < start_date || evaluation_end_date > end_date
    errors.add(:evaluation_end_date, :after_eval_start) if evaluation_end_date <= evaluation_start_date
  end

  def validate_evaluation_dates
    return unless evaluation_start_date.present? && evaluation_end_date.present?

    if evaluation_end_date - evaluation_start_date > 30.days
      errors.add(:evaluation_end_date, :too_long_evaluation_period)
    end
  end

  def set_quarter_name
    self.name ||= full_name
  end

  def set_as_current_if_first
    update!(is_current: true) if Quarter.count == 1
  end

  def handle_status_change
    return unless saved_change_to_status?

    if status == "closed"
      skill_ratings.where(status: %w[draft submitted]).update_all(status: "approved")
    end
  end
end
