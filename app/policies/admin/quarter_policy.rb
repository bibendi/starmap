# Policy for admin quarters management
class Admin::QuarterPolicy < Admin::BasePolicy
  def index?
    can_manage? || unit_lead?
  end

  def show?
    can_manage? || unit_lead?
  end

  def new?
    can_manage?
  end

  def create?
    can_manage?
  end

  def edit?
    can_manage? && record&.draft?
  end

  def update?
    edit?
  end

  def destroy?
    can_manage? && record&.draft?
  end

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
      return scope.none unless can_manage? || unit_lead?
      scope.all
    end

    def unit_lead?
      user&.unit_lead?
    end
  end
end
