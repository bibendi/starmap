# Quarter policy for role-based access control
class QuarterPolicy < ApplicationPolicy
  def index?
    active_user?
  end

  def show?
    return false unless active_user?
    return false unless record
    true
  end

  def create?
    can_manage_quarters?
  end

  def update?
    return false unless active_user?
    return false unless record
    return false unless record.draft?
    can_manage_quarters?
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

  def activate?
    return false unless active_user?
    return false unless record
    can_manage_quarters?
  end

  def close?
    return false unless active_user?
    return false unless record
    can_manage_quarters?
  end

  def archive?
    return false unless active_user?
    return false unless record
    can_manage_quarters?
  end

  def copy_ratings?
    return false unless active_user?
    return false unless record
    admin? || unit_lead? || team_lead?
  end

  def view_current?
    active_user?
  end

  def view_historical?
    active_user?
  end

  private

  def can_manage_quarters?
    admin? || unit_lead?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.active?
      scope.all
    end
  end
end
