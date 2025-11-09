# Team policy for role-based access control
class TeamPolicy < ApplicationPolicy
  def index?
    active_user?
  end

  def show?
    return false unless active_user?

    # Admins and unit leads can see all teams
    return true if admin? || unit_lead?

    # Team leads can see their own team
    return team_lead_of?(record) if team_lead?

    # Engineers can see their own team
    return user.team_id == record.id if engineer?

    false
  end

  def create?
    unit_lead? || admin?
  end

  def update?
    return false unless active_user?

    # Admins can update any team
    return true if admin?

    # Unit leads can update any team
    return true if unit_lead?

    # Team leads can update their own team
    return team_lead_of?(record) if team_lead?

    false
  end

  def destroy?
    admin?
  end

  def edit?
    update?
  end

  def new?
    create?
  end

  def manage_members?
    (unit_lead? || admin?) && (admin? || unit_lead? || team_lead_of?(record))
  end

  def assign_team_lead?
    unit_lead? || admin?
  end

  def view_team_metrics?
    active_user? &&
    (admin? || unit_lead? || team_lead_of?(record) || user.team_id == record.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin? || unit_lead?
        scope.all
      elsif team_lead?
        scope.where(id: user.team_id)
      else
        scope.where(id: user.team_id)
      end
    end
  end
end
