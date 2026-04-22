# frozen_string_literal: true

class CoverageIndexHistoryPolicy < ApplicationPolicy
  def index?
    return false unless active_user?
    return true if admin?

    record.all? { |team| accessible_team?(team) }
  end

  private

  def accessible_team?(team)
    return team.unit_id == user_unit_id if unit_lead?
    return user.team_id == team.id if team_lead? || engineer?

    false
  end

  def user_unit_id
    @user_unit_id ||= Unit.where(unit_lead_id: user.id).pick(:id)
  end
end
