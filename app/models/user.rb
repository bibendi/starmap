# User model for Starmap application
# Integrates Devise for database authentication
class User < ApplicationRecord
  # Include Devise modules for authentication
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  # Associations
  belongs_to :team, optional: true
  has_many :skill_ratings, dependent: :destroy
  has_many :action_plans, dependent: :destroy
  has_many :created_action_plans, class_name: 'ActionPlan', foreign_key: 'created_by_id', dependent: :nullify

  # Validations
  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :role, presence: true, inclusion: { in: %w[engineer team_lead unit_lead admin] }
  validates :email, presence: true, uniqueness: true


  # Callbacks
  before_validation :set_default_role, on: :create

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_role, ->(role) { where(role: role) }
  scope :engineers, -> { where(role: 'engineer') }
  scope :team_leads, -> { where(role: 'team_lead') }
  scope :unit_leads, -> { where(role: 'unit_lead') }
  scope :admins, -> { where(role: 'admin') }
  scope :by_team, ->(team_id) { where(team_id: team_id) }


  # Role checking methods
  def engineer?
    role == 'engineer'
  end

  def team_lead?
    role == 'team_lead'
  end

  def unit_lead?
    role == 'unit_lead'
  end

  def admin?
    role == 'admin' || admin == true
  end

  # Team leadership check
  def team_lead_of?(team)
    team_lead? && team_id == team.id
  end

  # Unit leadership check (can see all teams in unit)
  def unit_lead_of_unit?(unit)
    unit_lead? # For now, unit leads can see all units
  end

  # Name helpers
  def full_name
    [first_name, last_name].compact.join(' ')
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
    action_plans.where(status: 'completed')
  end

  # Team management helpers
  def team_members
    return User.none unless team_lead? || unit_lead? || admin?

    if admin? || unit_lead?
      User.where(team: team).where.not(id: id)
    elsif team_lead?
      User.where(team: team).where.not(id: id)
    else
      User.none
    end
  end

  # Permission helpers for Pundit
  def can_view_user?(other_user)
    return true if admin? || unit_lead?
    return true if other_user == self
    return team_lead_of?(other_user.team) if team_lead?
    false
  end

  def can_edit_user?(other_user)
    return true if admin?
    return other_user == self
    return team_lead_of?(other_user.team) if team_lead?
    false
  end

  def can_approve_skill_ratings?
    team_lead? || unit_lead? || admin?
  end

  def can_manage_teams?
    unit_lead? || admin?
  end

  def can_manage_technologies?
    admin?
  end

  def can_manage_quarters?
    admin?
  end

  def can_view_all_data?
    admin? || unit_lead?
  end

  def can_view_team_data?
    admin? || unit_lead? || team_lead?
  end

  private

  def set_default_role
    self.role ||= 'engineer'
  end
end
