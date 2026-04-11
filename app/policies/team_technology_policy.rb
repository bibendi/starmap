class TeamTechnologyPolicy < ApplicationPolicy
  def show?
    return false unless active_user?
    return false if record.blank?

    team = record.is_a?(Team) ? record : record.team
    return false unless team

    return true if admin? || unit_lead?

    team_lead_of?(team)
  end
end
