# Team policy for role-based access control
class TeamPolicy < ApplicationPolicy
  def index?
    user&.active?
  end

  def show?
    return false unless user&.active?

    # Admins and unit leads can see all teams
    return true if user.admin? || user.unit_lead?

    # Team leads can see their own team
    return user.team_lead_of?(record) if user.team_lead?

    # Engineers can see their own team
    return user.team_id == record.id if user.engineer?

    false
  end

  def create?
    user&.can_manage_teams?
  end

  def update?
    return false unless user&.active?

    # Admins can update any team
    return true if user.admin?

    # Unit leads can update any team
    return true if user.unit_lead?

    # Team leads can update their own team
    return user.team_lead_of?(record) if user.team_lead?

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

  def manage_members?
    user&.can_manage_teams? &&
    (user.admin? || user.unit_lead? || user.team_lead_of?(record))
  end

  def assign_team_lead?
    user&.can_manage_teams?
  end

  def view_team_metrics?
    user&.active? &&
    (user.admin? || user.unit_lead? || user.team_lead_of?(record) || user.team_id == record.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.unit_lead?
        scope.all
      elsif user.team_lead?
        scope.where(id: user.team_id)
      else
        scope.where(id: user.team_id)
      end
    end
  end
end
