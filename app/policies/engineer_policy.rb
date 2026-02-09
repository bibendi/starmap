class EngineerPolicy < ApplicationPolicy
  def show?
    return false unless active_user?

    user == record ||
      admin? ||
      unit_lead_viewing_team_member? ||
      team_lead_viewing_team_member?
  end

  private

  def unit_lead_viewing_team_member?
    return false unless unit_lead?
    return false if record.team.nil?

    record.team.unit&.unit_lead_id == user.id
  end

  def team_lead_viewing_team_member?
    return false unless team_lead?

    same_team?(record)
  end
end
