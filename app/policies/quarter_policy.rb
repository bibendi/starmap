# Quarter policy for role-based access control
class QuarterPolicy < ApplicationPolicy
  def index?
    user&.active?
  end

  def show?
    user&.active?
  end

  def create?
    user&.can_manage_quarters?
  end

  def update?
    user&.can_manage_quarters?
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

  def activate?
    user&.can_manage_quarters?
  end

  def close?
    user&.can_manage_quarters?
  end

  def copy_ratings?
    user&.active? && (user.admin? || user.unit_lead? || user.team_lead?)
  end

  def view_current?
    user&.active?
  end

  def view_historical?
    user&.active?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
