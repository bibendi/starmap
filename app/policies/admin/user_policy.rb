class Admin::UserPolicy < Admin::BasePolicy
  private

  def can_manage?
    user&.admin?
  end

  class Scope < Admin::BasePolicy::Scope
    def resolve
      can_manage? ? scope.all : scope.none
    end

    private

    def can_manage?
      user&.admin?
    end
  end
end
