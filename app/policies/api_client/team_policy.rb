# frozen_string_literal: true

class ApiClient::TeamPolicy < ApiClient::ApplicationPolicy
  def show?
    enabled? && has_permission?("teams:read") && can_access_team?(record)
  end

  def view_team_metrics?
    show?
  end
end
