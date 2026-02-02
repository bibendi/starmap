# User model for Starmap application
# Integrates Devise for database authentication
class User < ApplicationRecord
  # Include Devise modules for authentication
  devise :database_authenticatable,
    # :registerable,
    :recoverable,
    :rememberable,
    :trackable,
    :validatable

  # Associations
  belongs_to :team, optional: true
  has_many :skill_ratings, dependent: :destroy
  has_many :action_plans, dependent: :destroy
  has_many :created_action_plans, class_name: "ActionPlan", foreign_key: "created_by_id", dependent: :nullify

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true, inclusion: {in: %w[engineer team_lead unit_lead admin]}
  validates :email, presence: true, uniqueness: true

  # Callbacks
  before_validation :set_default_role, on: :create

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_role, ->(role) { where(role: role) }
  scope :engineers, -> { where(role: "engineer") }
  scope :team_leads, -> { where(role: "team_lead") }
  scope :unit_leads, -> { where(role: "unit_lead") }
  scope :admins, -> { where(role: "admin") }
  scope :by_team, ->(team_id) { where(team_id: team_id) }

  # Role checking methods
  def engineer?
    role == "engineer"
  end

  def team_lead?
    role == "team_lead"
  end

  def unit_lead?
    role == "unit_lead"
  end

  def admin?
    role == "admin" || admin == true
  end

  # Team leadership check
  def team_lead_of?(team)
    team_lead? && team_id == team.id
  end

  # Unit leadership check (returns the unit where user is unit lead)
  def unit
    return unless unit_lead?
    Unit.find_by(unit_lead_id: id)
  end

  # Unit leadership check (can see all teams in unit)
  def unit_lead_of_unit?(unit)
    unit_lead? && unit&.unit_lead_id == id
  end

  # Name helpers
  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def display_name_or_full_name
    display_name.presence || full_name
  end

  # Skill rating helpers
  def skill_rating_for(technology, quarter = nil)
    quarter ||= Quarter.current
    skill_ratings.find_by(technology: technology, quarter: quarter)
  end

  def skill_level_for(technology, quarter = nil)
    rating = skill_rating_for(technology, quarter)
    rating&.level
  end

  def has_skill_level?(technology, level, quarter = nil)
    skill_level_for(technology, quarter) == level
  end

  def skill_level_at_least?(technology, level, quarter = nil)
    current_level = skill_level_for(technology, quarter)
    current_level.present? && current_level >= level
  end

  # Action plan helpers
  def active_action_plans
    action_plans.where(status: %w[in_progress pending])
  end

  def completed_action_plans
    action_plans.where(status: "completed")
  end

  # Team management helpers
  def team_members
    return [] if team.blank?
    team.users.where.not(id: id)
  end

  private

  def set_default_role
    self.role ||= "engineer"
  end
end
