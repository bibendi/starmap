# Technology policy for role-based access control
class TechnologyPolicy < ApplicationPolicy
  def index?
    user&.active?
  end

  def show?
    user&.active?
  end

  def create?
    user&.can_manage_technologies?
  end

  def update?
    user&.can_manage_technologies?
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

  def manage_criticality?
    user&.can_manage_technologies?
  end

  def view_technology_metrics?
    user&.active?
  end

  def bulk_update?
    user&.can_manage_technologies?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
