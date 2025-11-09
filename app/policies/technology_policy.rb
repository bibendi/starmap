# Technology policy for role-based access control
class TechnologyPolicy < ApplicationPolicy
  def index?
    active_user?
  end

  def show?
    active_user?
  end

  def create?
    can_manage_technologies?
  end

  def update?
    can_manage_technologies?
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

  def manage_criticality?
    can_manage_technologies?
  end

  def view_technology_metrics?
    active_user?
  end

  def bulk_update?
    can_manage_technologies?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
