class Admin::TechnologyPolicy < Admin::BasePolicy
  def can_manage?
    admin? || unit_lead?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
