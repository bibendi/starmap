# Navigation policy for view-level authorization
class NavigationPolicy < ApplicationPolicy
  def show_team_dashboard?
    team_lead? || unit_lead? || admin?
  end

  def show_admin?
    admin?
  end

  def show_personal_dashboard?
    user.present?
  end
end
