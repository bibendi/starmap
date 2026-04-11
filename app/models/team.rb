# Team model for Starmap application
# Represents teams within units with team leads
class Team < ApplicationRecord
  # Associations
  belongs_to :team_lead, class_name: "User", optional: true
  belongs_to :unit, optional: false
  has_many :users, dependent: :restrict_with_error
  has_many :skill_ratings, through: :users
  has_many :team_technologies, dependent: :destroy
  has_many :technologies, through: :team_technologies

  # Validations
  validates :name, presence: true, uniqueness: true
  validate :team_lead_must_be_member, on: :update

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_unit, ->(unit) { where(unit: unit) }
  scope :ordered, -> { order(:name) }

  # Delegation
  delegate :name, to: :unit, prefix: true, allow_nil: false

  def member_count
    users.active.count
  end

  def sync_members!(member_ids)
    member_ids = Array(member_ids).map(&:to_i)
    current_ids = user_ids
    added_ids = member_ids - current_ids
    removed_ids = current_ids - member_ids

    User.where(id: added_ids).find_each do |user|
      old_team = user.team
      old_team&.update!(team_lead_id: nil) if old_team&.team_lead_id == user.id
      user.update!(team_id: id)
    end

    User.where(id: removed_ids).find_each do |user|
      user.update!(team_id: nil)
    end

    update!(team_lead_id: nil) if team_lead_id.present? && !member_ids.include?(team_lead_id)
  end

  private

  def team_lead_must_be_member
    return if team_lead_id.blank?
    return if User.exists?(id: team_lead_id, team_id: id)

    errors.add(:team_lead_id, :team_lead_must_be_member)
  end
end
