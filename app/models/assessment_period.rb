# frozen_string_literal: true

class AssessmentPeriod < ApplicationRecord
  belongs_to :created_by, class_name: "User", optional: true
  has_many :skill_ratings, dependent: :destroy
  has_many :users, through: :skill_ratings
  has_many :technologies, through: :skill_ratings

  enum :status, %w[draft active closed archived].index_with(&:itself), default: "draft"
  enum :period_kind, %w[monthly quarterly semiannual annual custom].index_with(&:itself), default: "quarterly", validate: true

  attr_writer :calendar_year, :calendar_number

  validates :name, :start_date, :end_date, :evaluation_start_date, :evaluation_end_date, presence: true
  validate :validate_dates
  validate :validate_calendar
  validate :validate_non_overlapping

  before_validation :apply_calendar_selection
  before_validation :set_period_name
  after_create :set_as_current_if_first
  after_update :approve_ratings_on_close

  scope :ordered, -> { order(:start_date, :end_date, :id) }

  def self.calendar_bounds(kind, year, number = 1)
    return unless year.to_s.match?(/\A\d{4,}\z/) && year.to_i > 2000

    lengths = {"monthly" => 1, "quarterly" => 3, "semiannual" => 6, "annual" => 12}
    months = lengths[kind]
    return unless months && number.to_s.match?(/\A\d+\z/) && (1..(12 / months)).cover?(number.to_i)

    start_date = Date.new(year.to_i, (number.to_i - 1) * months + 1, 1)
    [start_date, start_date.advance(months: months) - 1.day]
  end

  def calendar_year
    @calendar_year || start_date&.year
  end

  def calendar_number
    return @calendar_number if @calendar_number
    return unless start_date

    months = {"monthly" => 1, "quarterly" => 3, "semiannual" => 6, "annual" => 12}[period_kind]
    ((start_date.month - 1) / months) + 1 if months
  end

  def full_name
    return name if name.present?
    return unless start_date && end_date

    case period_kind
    when "monthly" then start_date.strftime("%Y-%m")
    when "quarterly" then "#{start_date.year} Q#{calendar_number}"
    when "semiannual" then "#{start_date.year} H#{calendar_number}"
    when "annual" then start_date.year.to_s
    else "#{start_date.iso8601} – #{end_date.iso8601}"
    end
  end

  def evaluation_period?
    evaluation_start_date && evaluation_end_date && Date.current.between?(evaluation_start_date, evaluation_end_date)
  end

  def previous_assessment_period
    self.class.where("end_date < ?", start_date).order(:end_date).last
  end

  def self.current
    find_by(is_current: true)
  end

  private

  def apply_calendar_selection
    return if custom? || (@calendar_year.nil? && @calendar_number.nil?)

    bounds = self.class.calendar_bounds(period_kind, calendar_year, annual? ? 1 : calendar_number)
    if bounds
      self.start_date, self.end_date = bounds
    else
      errors.add(:start_date, :invalid_calendar)
    end
  end

  def set_period_name
    return if name.present? && !will_save_change_to_start_date? && !will_save_change_to_end_date? && !will_save_change_to_period_kind?
    return if new_record? && name.present?

    self.name = nil
    self.name = full_name
  end

  def validate_dates
    errors.add(:end_date, :after_start_date) if start_date && end_date && end_date <= start_date
    errors.add(:evaluation_start_date, :after_assessment_period_end) if evaluation_start_date && end_date && evaluation_start_date < end_date
    if evaluation_start_date && evaluation_end_date && evaluation_end_date <= evaluation_start_date
      errors.add(:evaluation_end_date, :after_eval_start)
    end
  end

  def validate_calendar
    return if custom? || start_date.nil? || end_date.nil?
    return if self.class.calendar_bounds(period_kind, start_date.year, calendar_number) == [start_date, end_date]

    errors.add(:start_date, :invalid_calendar)
  end

  def validate_non_overlapping
    return unless start_date && end_date && end_date > start_date
    return unless self.class.where.not(id: id).where("start_date <= ? AND end_date >= ?", end_date, start_date).exists?

    errors.add(:base, :overlap)
  end

  def set_as_current_if_first
    update!(is_current: true) if self.class.count == 1 && !is_current?
  end

  def approve_ratings_on_close
    skill_ratings.where(status: %w[draft submitted]).update_all(status: "approved") if saved_change_to_status? && closed?
  end
end
