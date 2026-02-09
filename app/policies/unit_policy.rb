# Unit policy for role‑based access control
class UnitPolicy < ApplicationPolicy
  def index?
    active_user?
  end

  def show?
    return false unless active_user?
    return false if record.blank?

    return true if admin? && record.persisted?
    return record.unit_lead_id == user.id if unit_lead?

    false
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user&.role == "admin"
        scope.all
      elsif user&.role == "unit_lead"
        scope.where(unit_lead_id: user.id)
      else
        scope.none
      end
    end
  end
end
