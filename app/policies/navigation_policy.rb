# Navigation policy for view-level authorization
class NavigationPolicy < ApplicationPolicy
  def show_team_dashboard?
    active_user? && (team_lead? || unit_lead? || admin?)
  end

  def show_admin?
    active_user? && admin?
  end

  def show_personal_dashboard?
    active_user?
  end
end
