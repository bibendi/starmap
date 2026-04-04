class Admin::TeamTechnologyPolicy < Admin::BasePolicy
  def update?
    can_manage? && (admin? || unit_lead_owns_record?)
  end

  def destroy?
    can_manage? && (admin? || unit_lead_owns_record?)
  end

  def permitted_attributes
    [:technology_id, :criticality, :target_experts]
  end

  private

  def can_manage?
    admin? || unit_lead?
  end

  def unit_lead_owns_record?
    return false unless unit_lead?

    team_record.team.unit_id == user.unit&.id
  end

  def team_record
    record.is_a?(Array) ? record.last : record
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if can_manage?
        unit_lead? ? scope.joins(:team).where(teams: {unit_id: user.unit.id}) : scope.all
      else
        scope.none
      end
    end

    private

    def can_manage?
      user&.admin? || user&.unit_lead?
    end

    def unit_lead?
      user&.unit_lead?
    end
  end
end
