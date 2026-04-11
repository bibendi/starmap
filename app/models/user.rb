class User < ApplicationRecord
  devise :database_authenticatable,
    :recoverable,
    :rememberable,
    :trackable,
    :validatable

  belongs_to :team, optional: true
  has_many :skill_ratings, dependent: :destroy

  enum :role, {
    engineer: "engineer",
    team_lead: "team_lead",
    unit_lead: "unit_lead",
    admin: "admin"
  }, default: "engineer"

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true, uniqueness: true
  validate :only_one_team_lead_per_team, if: :team_lead_role_changed?

  scope :active, -> { where(active: true) }
  scope :unassigned_engineers, -> { engineer.where(team_id: nil) }

  def active_for_authentication?
    super && active?
  end

  def team_lead_of?(team)
    team_lead? && team_id == team.id
  end

  def unit
    return unless unit_lead?
    Unit.find_by(unit_lead_id: id)
  end

  def full_name
    [first_name, last_name].compact.join(" ")
  end

  def display_name_or_full_name
    display_name.presence || full_name
  end

  private

  def team_lead_role_changed?
    team_lead? && (role_changed? || team_id_changed?)
  end

  def only_one_team_lead_per_team
    return if team_id.blank?

    existing_lead = User.team_lead.where(team_id: team_id).where.not(id: id).exists?
    return unless existing_lead

    errors.add(:base, :team_already_has_lead)
  end
end
