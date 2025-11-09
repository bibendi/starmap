# User policy for role-based access control
class UserPolicy < ApplicationPolicy
  def index?
    active_user? && (admin? || unit_lead? || team_lead?)
  end

  def show?
    return false unless active_user?
    return false unless record

    # Users can see themselves
    return true if record == user

    # Admins and unit leads can see everyone
    return true if admin? || unit_lead?

    # Team leads can see their team members
    return team_lead_of?(record.team) if team_lead?

    false
  end

  def create?
    return false unless active_user?
    admin? || unit_lead?
  end

  def update?
    return false unless active_user?
    return false unless record

    # Users can update themselves (limited fields)
    return true if record == user

    # Admins can update anyone
    return true if admin?

    # Unit leads can update anyone
    return true if unit_lead?

    # Team leads can update their team members
    return team_lead_of?(record.team) if team_lead?

    false
  end

  def destroy?
    return false unless active_user?
    return false unless record
    admin?
  end

  def edit?
    update?
  end

  def new?
    create?
  end

  def view_sensitive_data?
    return false unless active_user?
    admin? || unit_lead?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      if user.admin? || user.unit_lead?
        scope.all
      elsif user.team_lead?
        scope.where(team: user.team)
      else
        scope.where(id: user.id)
      end
    end
  end
end
