# Technology policy for role-based access control
class TechnologyPolicy < ApplicationPolicy
  def index?
    active_user?
  end

  def show?
    return false unless active_user?
    return false unless record
    true
  end

  def create?
    can_manage_technologies?
  end

  def update?
    return false unless active_user?
    return false unless record
    can_manage_technologies?
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

  def manage_criticality?
    return false unless active_user?
    return false unless record
    can_manage_technologies?
  end

  def view_technology_metrics?
    active_user?
  end

  def bulk_update?
    return false unless active_user?
    return false unless record
    can_manage_technologies?
  end

  private

  def can_manage_technologies?
    admin? || unit_lead?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user&.active?
      scope.all
    end
  end
end
