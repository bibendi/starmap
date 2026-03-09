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

  class Scope < Admin::BasePolicy::Scope
    def resolve
      return scope.none unless can_manage?
      scope.all
    end
  end
end
