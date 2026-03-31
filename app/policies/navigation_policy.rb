# Navigation policy for view-level authorization
class NavigationPolicy < ApplicationPolicy
  def show_team?
    active_user? && (team_lead? || unit_lead? || admin?)
  end

  def show_admin?
    active_user? && (admin? || unit_lead?)
  end

  def show_personal_dashboard?
    active_user?
  end

  def show_unit?
    active_user? && (unit_lead? || admin?)
  end
end
