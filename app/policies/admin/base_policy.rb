# Base policy for admin namespace
class Admin::BasePolicy < ApplicationPolicy
  def index?
    can_manage?
  end

  def show?
    can_manage?
  end

  def create?
    can_manage?
  end

  def update?
    can_manage?
  end

  def destroy?
    can_manage?
  end

  def new?
    create?
  end

  def edit?
    update?
  end

  private

  def can_manage?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      can_manage? ? scope.all : scope.none
    end

    private

    def can_manage?
      user&.admin?
    end
  end
end
