# SkillRating model for Starmap application
# Represents skill evaluations on 0-3 scale for users, technologies, and quarters
class SkillRating < ApplicationRecord
  # Associations
  belongs_to :user, inverse_of: :skill_ratings
  belongs_to :technology
  belongs_to :quarter
  belongs_to :team
  belongs_to :approved_by, class_name: "User", optional: true
  belongs_to :created_by, class_name: "User", optional: true
  belongs_to :updated_by, class_name: "User", optional: true

  # Validations
  validates :rating, presence: true, inclusion: {in: 0..3}
  validates :status, presence: true, inclusion: {in: %w[draft submitted approved rejected]}

  # Validate unique combination of user, technology, quarter
  validates :user_id, uniqueness: {scope: [:technology_id, :quarter_id], message: "уже имеет оценку для этой технологии в данном квартале"}

  # Validate rating based on status
  validate :validate_rating_for_status

  # Callbacks
  before_validation :set_default_status, on: :create
  before_validation :set_team_from_user, if: -> { team_id.nil? && user_id.present? }
  before_update :set_updated_by, if: :saved_changes?
  after_update :handle_approval_change, if: :status_changed?
  after_update :handle_lock_change, if: :locked_changed?

  # Scopes
  scope :by_quarter, ->(quarter) { where(quarter: quarter) }
  scope :by_user, ->(user) { where(user: user) }
  scope :by_technology, ->(technology) { where(technology: technology) }
  scope :by_rating, ->(rating) { where(rating: rating) }
  scope :approved, -> { where(status: "approved") }
  scope :draft, -> { where(status: "draft") }
  scope :submitted, -> { where(status: "submitted") }
  scope :locked, -> { where(locked: true) }
  scope :unlocked, -> { where(locked: false) }
  scope :high_skills, -> { where(rating: 2..3) }
  scope :experts, -> { where(rating: 2..3) }
  scope :novices, -> { where(rating: 0..1) }
  scope :active_users, -> { joins(:user).where(users: {active: true}) }
  scope :active_technologies, -> { joins(:technology).where(technologies: {active: true}) }

  # Scope for current quarter ratings
  scope :current, -> { by_quarter(Quarter.current) }

  # Rating level helpers
  def level
    case rating
    when 0 then "Не имею представления"
    when 1 then "Имею представление"
    when 2 then "Свободно владею"
    when 3 then "Могу учить других"
    else "Неизвестно"
    end
  end

  def level_short
    case rating
    when 0 then "Нет"
    when 1 then "Базовый"
    when 2 then "Продвинутый"
    when 3 then "Эксперт"
    else "?"
    end
  end

  def expert_level?
    rating >= 2
  end

  def novice_level?
    rating <= 1
  end

  def can_be_edited?
    !locked && !approved?
  end

  def can_be_approved?
    draft? || submitted?
  end

  def can_be_submitted?
    draft?
  end

  def can_be_rejected?
    submitted?
  end

  # Status helpers
  def draft?
    status == "draft"
  end

  def submitted?
    status == "submitted"
  end

  def approved?
    status == "approved"
  end

  def rejected?
    status == "rejected"
  end

  def approved_or_rejected?
    approved? || rejected?
  end

  # Approval workflow
  def submit_for_approval
    update!(status: "submitted") if draft?
  end

  def approve!(approver)
    return false unless can_be_approved?

    update!(
      status: "approved",
      approved_by: approver,
      approved_at: Time.current
    )
  end

  def reject!(approver, reason = nil)
    return false unless can_be_rejected?

    update!(
      status: "rejected",
      approved_by: approver,
      approved_at: Time.current,
      comment: [comment, "Отклонено: #{reason}"].compact.join("\n")
    )
  end

  def resubmit
    update!(status: "draft") if rejected?
  end

  # Lock management
  def lock!
    update!(locked: true) unless locked?
  end

  def unlock!
    update!(locked: false) if locked?
  end

  # Rating change tracking
  def rating_changed?
    saved_change_to_rating?
  end

  def previous_rating
    rating_before_last_save
  end

  def rating_improvement
    return 0 unless rating_changed?
    rating - previous_rating
  end

  def rating_decline
    return 0 unless rating_changed?
    previous_rating - rating
  end

  def significant_improvement?
    rating_improvement >= 1
  end

  def significant_decline?
    rating_decline >= 1
  end

  # Context helpers
  def user_team
    user.team
  end

  def technology_criticality
    technology.criticality
  end

  def is_critical_technology?
    technology.high_criticality?
  end

  # Analytics helpers
  def self.rating_distribution(quarter = nil)
    quarter ||= Quarter.current
    distribution = {0 => 0, 1 => 0, 2 => 0, 3 => 0}

    active_users.active_technologies.by_quarter(quarter).each do |rating|
      distribution[rating.rating] += 1
    end

    distribution
  end

  def self.average_rating(quarter = nil)
    quarter ||= Quarter.current
    active_users.active_technologies.by_quarter(quarter).average(:rating).to_f.round(2)
  end

  def self.expert_count(technology, quarter = nil)
    quarter ||= Quarter.current
    experts.by_technology(technology).by_quarter(quarter).count
  end

  def self.coverage_percentage(technology, quarter = nil)
    quarter ||= Quarter.current
    total_users = User.active.count
    return 0 if total_users.zero?

    rated_users = by_technology(technology).by_quarter(quarter).active_users.distinct.count
    (rated_users.to_f / total_users * 100).round(2)
  end

  def self.team_maturity_index(team, quarter = nil)
    quarter ||= Quarter.current
    team_ratings = by_quarter(quarter).where(team: team)
    total_ratings = team_ratings.count
    return 0 if total_ratings.zero?

    high_skills = team_ratings.where(rating: 3).count
    (high_skills.to_f / total_ratings * 100).round(2)
  end

  def self.technology_maturity_index(technology, quarter = nil)
    quarter ||= Quarter.current
    tech_ratings = by_technology(technology).by_quarter(quarter)
    total_ratings = tech_ratings.count
    return 0 if total_ratings.zero?

    high_skills = tech_ratings.where(rating: 3).count
    (high_skills.to_f / total_ratings * 100).round(2)
  end

  # Comparison with previous quarters
  def previous_rating_for_same_technology
    return nil if quarter.previous_quarter.blank?

    SkillRating.find_by(
      user: user,
      technology: technology,
      quarter: quarter.previous_quarter
    )
  end

  def rating_trend
    previous = previous_rating_for_same_technology
    return nil unless previous

    {
      previous_rating: previous.rating,
      current_rating: rating,
      change: rating - previous.rating,
      trend: case (rating - previous.rating)
             when 1 then "improved"
             when -1 then "declined"
             when 0 then "stable"
             else "significant_change"
             end
    }
  end

  # Class methods for bulk operations
  def self.copy_ratings_to_new_quarter(from_quarter, to_quarter, created_by)
    copied_count = 0
    from_quarter.skill_ratings.each do |old_rating|
      next if exists?(user: old_rating.user, technology: old_rating.technology, quarter: to_quarter)

      create!(
        user: old_rating.user,
        technology: old_rating.technology,
        quarter: to_quarter,
        rating: old_rating.rating,
        comment: "Скопировано из #{from_quarter.full_name}",
        status: "draft",
        team_id: old_rating.team_id,
        created_by: created_by
      )
      copied_count += 1
    end
    copied_count
  end

  def self.lock_all_for_quarter(quarter)
    by_quarter(quarter).update_all(locked: true)
  end

  def self.unlock_all_for_quarter(quarter)
    by_quarter(quarter).update_all(locked: false)
  end

  def self.approve_all_for_quarter(quarter, approver)
    by_quarter(quarter).where(status: %w[draft submitted]).update_all(
      status: "approved",
      approved_by: approver,
      approved_at: Time.current
    )
  end

  private

  def validate_rating_for_status
    return if rating.blank?

    if rating == 0 && approved?
      errors.add(:rating, "не может быть 0 для утвержденной оценки")
    end
  end

  def set_default_status
    self.status ||= "draft"
  end

  def set_team_from_user
    self.team_id = user.team_id if user.present?
  end

  def set_updated_by
    # This would be set by the controller, but we can have a fallback
    self.updated_by_id ||= User.first&.id
  end

  def handle_approval_change
    if approved?
      self.approved_at ||= Time.current
      self.approved_by ||= User.first # Fallback
    elsif draft?
      self.approved_at = nil
      self.approved_by = nil
    end
  end

  def handle_lock_change
    # Additional logic when lock status changes
    # Could trigger notifications or other side effects
  end
end
