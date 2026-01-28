# Team policy for role-based access control
class TeamPolicy < ApplicationPolicy
  def index?
    active_user?
  end

  def show?
    return false unless active_user?
    return false if record.blank?

    # Admins and unit leads can see all teams
    return true if admin? || unit_lead?

    # Team leads can see their own team
    return team_lead_of?(record) if team_lead?

    # Engineers can see their own team
    return user.team_id.present? && user.team_id == record.id if engineer?

    false
  end

  def create?
    unit_lead? || admin?
  end

  def update?
    return false unless active_user?
    return false if record.blank?

    # Admins can update any team
    return true if admin?

    # Unit leads can update any team
    return true if unit_lead?

    # Team leads can update their own team
    return team_lead_of?(record) if team_lead?

    false
  end

  def destroy?
    return false if record.blank?
    admin?
  end

  def edit?
    return false if record.blank?
    update?
  end

  def new?
    create?
  end

  def manage_members?
    return false if record.blank?

    # Admins and unit leads can manage members in any team
    return true if admin? || unit_lead?

    # Team leads can manage members in their own team
    return team_lead_of?(record) if team_lead?

    false
  end

  def assign_team_lead?
    return false if record.blank?
    unit_lead? || admin?
  end

  def view_team_metrics?
    return false unless active_user?
    return false if record.blank?

    # Admins, unit leads, team leads of the team, or team members can view metrics
    admin? || unit_lead? || team_lead_of?(record) || (user.team_id.present? && user.team_id == record.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.role == "admin" || user&.role == "unit_lead"
        scope.all
      elsif user&.role == "team_lead"
        scope.where(id: user.team_id)
      elsif user
        scope.where(id: user.team_id)
      else
        scope.none
      end
    end
  end
end
