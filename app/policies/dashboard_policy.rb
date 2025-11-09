class DashboardPolicy < ApplicationPolicy
  def overview?
    active_user?
  end

  def team?
    team_lead? || unit_lead? || admin?
  end

  def personal?
    record == user || team_lead? || unit_lead? || admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if unit_lead? || admin?
        scope.all
      elsif team_lead?
        scope.where(user: { team: user.team })
      else
        scope.where(user: user)
      end
    end
  end
end
