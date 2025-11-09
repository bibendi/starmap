# Quarter policy for role-based access control
class QuarterPolicy < ApplicationPolicy
  def index?
    active_user?
  end

  def show?
    active_user?
  end

  def create?
    can_manage_quarters?
  end

  def update?
    can_manage_quarters?
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

  def activate?
    can_manage_quarters?
  end

  def close?
    can_manage_quarters?
  end

  def copy_ratings?
    active_user? && (admin? || unit_lead? || team_lead?)
  end

  def view_current?
    active_user?
  end

  def view_historical?
    active_user?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
