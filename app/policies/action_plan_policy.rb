# ActionPlan policy for role-based access control
class ActionPlanPolicy < ApplicationPolicy
  def index?
    active_user?
  end

  def show?
    return false unless active_user?

    # Handle nil record case
    return false unless record

    # Users can see their own action plans
    return true if own_record?(record) || record.user_id == user.id

    # Admins and unit leads can see all action plans
    return true if admin? || unit_lead?

    # Team leads can see their team's action plans
    return team_lead_of?(record.user.team) if team_lead? && record.user&.team

    # Users can see action plans where they are assigned
    return record.assigned_to_id == user.id if record.assigned_to_id.present?

    false
  end

  def create?
    return false unless active_user?

    # Admins and unit leads can create action plans for anyone
    return true if admin? || unit_lead?

    # Team leads can create action plans for their team members
    return true if team_lead? && record.user_id.present? && team_lead_of?(User.find(record.user_id)&.team)

    # Users can create action plans for themselves
    return record.user_id == user.id if record.user_id.present?

    false
  end

  def update?
    return false unless active_user?

    # Handle nil record case
    return false unless record

    # Users can update their own action plans
    return true if own_record?(record) || record.user_id == user.id

    # Admins and unit leads can update any action plan
    return true if admin? || unit_lead?

    # Team leads can update their team's action plans
    return team_lead_of?(record.user.team) if team_lead? && record.user&.team

    # Assigned users can update action plans assigned to them
    return record.assigned_to_id == user.id if record.assigned_to_id.present?

    # Users without team cannot update action plans of others
    return false if user.team.nil?

    false
  end

  def destroy?
    return false unless active_user?

    # Handle nil record case
    return false unless record

    admin?
  end

  def edit?
    update?
  end

  def new?
    create?
  end

  def approve?
    return false unless active_user?

    # Handle nil record case
    return false unless record

    (team_lead? || unit_lead? || admin?) &&
      (admin? || unit_lead? || (team_lead? && record.user&.team && team_lead_of?(record.user.team)))
  end

  def complete?
    update?
  end

  def pause?
    update?
  end

  def resume?
    update?
  end

  def assign_to?
    return false unless active_user?

    # Handle nil record case
    return false unless record

    admin? || unit_lead? || (team_lead? && record.user&.team && team_lead_of?(record.user.team))
  end

  def view_progress?
    return false unless active_user?

    # Handle nil record case
    return false unless record

    admin? || unit_lead? ||
      (team_lead? && record.user&.team && team_lead_of?(record.user.team)) ||
      record.user_id == user.id || record.assigned_to_id == user.id ||
      (user.team.nil? && record.user_id == user.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      if user.admin? || user.unit_lead?
        scope.all
      elsif user.team_lead?
        scope.joins(:user).where(users: {team_id: user.team_id}).or(scope.where(assigned_to_id: user.id))
      else
        scope.where(user_id: user.id).or(scope.where(assigned_to_id: user.id))
      end
    end
  end
end
