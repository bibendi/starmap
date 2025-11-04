# User policy for role-based access control
class UserPolicy < ApplicationPolicy
  def index?
    user&.active? && (user.admin? || user.unit_lead? || user.team_lead?)
  end

  def show?
    return false unless user&.active?

    # Users can see themselves
    return true if record == user

    # Admins and unit leads can see everyone
    return true if user.admin? || user.unit_lead?

    # Team leads can see their team members
    return user.team_lead_of?(record.team) if user.team_lead?

    false
  end

  def create?
    user&.admin? || user&.unit_lead?
  end

  def update?
    return false unless user&.active?

    # Users can update themselves (limited fields)
    return true if record == user

    # Admins can update anyone
    return true if user.admin?

    # Unit leads can update anyone
    return true if user.unit_lead?

    # Team leads can update their team members
    return user.team_lead_of?(record.team) if user.team_lead?

    false
  end

  def destroy?
    user&.admin?
  end

  def edit?
    update?
  end

  def new?
    create?
  end

  def approve_skill_ratings?
    user&.can_approve_skill_ratings? &&
    (user.admin? || user.unit_lead? || user.team_lead_of?(record.team))
  end

  def manage_team?
    user&.can_manage_teams? &&
    (user.admin? || user.unit_lead? || user.team_lead_of?(record.team))
  end

  def view_sensitive_data?
    user&.admin? || user&.unit_lead?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
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
