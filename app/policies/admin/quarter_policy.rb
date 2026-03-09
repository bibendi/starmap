# Policy for admin quarters management
class Admin::QuarterPolicy < Admin::BasePolicy
  def activate?
    can_manage?
  end

  def close?
    can_manage?
  end

  def archive?
    can_manage?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none if !user&.active? && !(user.admin? || user.unit_lead?)
      scope.all
    end
  end
end
