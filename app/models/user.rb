class User < ApplicationRecord
  devise_modules = [:database_authenticatable, :recoverable, :rememberable, :trackable, :validatable]
  devise_modules << :registerable if REGISTRATION_ENABLED
  devise_modules << :omniauthable if OIDC_ENABLED
  devise_options = {}
  devise_options[:omniauth_providers] = [:oidc] if OIDC_ENABLED
  devise(*devise_modules, **devise_options)

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

  def self.pending_approvals_count(approver)
    return 0 unless approver
    return 0 if approver.engineer?

    current_quarter = Quarter.current
    return 0 unless current_quarter

    user_ids_scope = case approver.role
    when "admin"
      submitted_rating_user_ids(current_quarter)
    when "unit_lead"
      unit = Unit.find_by(unit_lead_id: approver.id)
      return 0 unless unit
      team_ids = unit.teams.pluck(:id)
      submitted_rating_user_ids(current_quarter, team_ids: team_ids, roles: ["team_lead"])
    when "team_lead"
      submitted_rating_user_ids(current_quarter, team_ids: [approver.team_id])
    else
      return 0
    end

    user_ids_scope.count
  end

  def self.users_with_pending_approvals(approver)
    return User.none unless approver
    return User.none if approver.engineer?

    current_quarter = Quarter.current
    return User.none unless current_quarter

    ids = case approver.role
    when "admin"
      submitted_rating_user_ids(current_quarter)
    when "unit_lead"
      unit = Unit.find_by(unit_lead_id: approver.id)
      return User.none unless unit
      submitted_rating_user_ids(current_quarter, team_ids: unit.teams.pluck(:id), roles: ["team_lead"])
    when "team_lead"
      submitted_rating_user_ids(current_quarter, team_ids: [approver.team_id])
    else
      return User.none
    end

    User.where(id: ids).order(:first_name, :last_name)
  end

  def self.submitted_rating_user_ids(quarter, team_ids: nil, roles: nil)
    scope = SkillRating.where(quarter: quarter, status: :submitted)
    scope = scope.where(team_id: team_ids) if team_ids
    scope = scope.joins(:user).where(users: {role: roles}) if roles
    scope.select(:user_id).distinct
  end

  def self.from_omniauth(auth)
    user = find_by(provider: auth.provider, uid: auth.uid)
    return user if user

    email = auth.info.email
    raise "OIDC provider did not return email" if email.blank?

    user = find_by(email: email)
    if user
      user.update_columns(provider: auth.provider, uid: auth.uid)
      return user
    end

    create!(
      provider: auth.provider,
      uid: auth.uid,
      email: email,
      first_name: auth.info.first_name || auth.info.name.to_s.split(" ").first,
      last_name: auth.info.last_name || auth.info.name.to_s.split(" ").last,
      password: Devise.friendly_token[0, 20],
      role: :engineer,
      active: true,
      confirmed_at: Time.current
    )
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
