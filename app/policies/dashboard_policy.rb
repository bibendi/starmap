class DashboardPolicy < ApplicationPolicy
  def overview?
    user&.active?
  end

  def team?
    user&.team_lead? || user&.unit_lead? || user&.admin?
  end

  def personal?
    record == user || user&.team_lead? || user&.unit_lead? || user&.admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.unit_lead? || user&.admin?
        scope.all
      elsif user&.team_lead?
        scope.where(user: { team: user.team })
      else
        scope.where(user: user)
      end
    end
  end
end
