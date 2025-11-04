# ActionPlan policy for role-based access control
class ActionPlanPolicy < ApplicationPolicy
  def index?
    user&.active?
  end

  def show?
    return false unless user&.active?

    # Users can see their own action plans
    return true if own_record?(record) || record.user_id == user.id

    # Admins and unit leads can see all action plans
    return true if user.admin? || user.unit_lead?

    # Team leads can see their team's action plans
    return user.team_lead_of?(record.user.team) if user.team_lead?

    # Users can see action plans where they are assigned
    return record.assigned_to_id == user.id if record.assigned_to_id.present?

    false
  end

  def create?
    return false unless user&.active?

    # Admins and unit leads can create action plans for anyone
    return true if user.admin? || user.unit_lead?

    # Team leads can create action plans for their team members
    return true if user.team_lead? && record.user_id.present? && user.team_lead_of?(User.find(record.user_id)&.team)

    # Users can create action plans for themselves
    return record.user_id == user.id if record.user_id.present?

    false
  end

  def update?
    return false unless user&.active?

    # Users can update their own action plans
    return true if own_record?(record) || record.user_id == user.id

    # Admins and unit leads can update any action plan
    return true if user.admin? || user.unit_lead?

    # Team leads can update their team's action plans
    return user.team_lead_of?(record.user.team) if user.team_lead?

    # Assigned users can update action plans assigned to them
    return record.assigned_to_id == user.id if record.assigned_to_id.present?

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

  def approve?
    user&.can_approve_skill_ratings? &&
    (user.admin? || user.unit_lead? || user.team_lead_of?(record.user.team))
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
    user&.active? &&
    (user.admin? || user.unit_lead? || user.team_lead_of?(record.user.team))
  end

  def view_progress?
    user&.active? &&
    (user.admin? || user.unit_lead? || user.team_lead_of?(record.user.team) ||
     record.user_id == user.id || record.assigned_to_id == user.id)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.unit_lead?
        scope.all
      elsif user.team_lead?
        scope.joins(:user).where(users: { team_id: user.team_id })
      else
        scope.where(user_id: user.id).or(scope.where(assigned_to_id: user.id))
      end
    end
  end
end
