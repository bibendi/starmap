# Base policy class for Starmap application
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must implement #resolve"
    end
  end

  private

  # Helper methods for role checking
  def engineer?
    user&.role == "engineer"
  end

  def team_lead?
    user&.role == "team_lead"
  end

  def unit_lead?
    user&.role == "unit_lead"
  end

  def admin?
    user&.role == "admin" || user&.admin?
  end

  def team_lead_of?(team)
    team && team_lead? && user.team_id == team.id
  end

  def unit_lead_of_unit?(unit)
    unit_lead? # For now, unit leads can see all units
  end

  def same_team?(other_user)
    user.team_id == other_user.team_id
  end

  def own_record?(record)
    record.respond_to?(:user_id) && record.user_id == user.id
  end

  def active_user?
    user&.active?
  end
end
