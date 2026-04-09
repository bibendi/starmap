# SkillRating policy for role-based access control
class SkillRatingPolicy < ApplicationPolicy
  def index?
    active_user?
  end

  def show?
    return false unless active_user?

    # Users can see their own ratings
    return true if own_record?(record)

    # Admins and unit leads can see all ratings
    return true if admin? || unit_lead?

    # Team leads can see their team's ratings
    return team_lead_of?(record.user.team) if team_lead?

    false
  end

  def create?
    return false unless active_user?

    return true if own_record?(record)

    admin?
  end

  def update?
    return false unless active_user?
    return false unless record

    return true if own_record?(record) && !record.approved?

    admin?
  end

  def destroy?
    return false unless record
    admin?
  end

  def approve?
    return false unless record
    (team_lead? || unit_lead? || admin?) &&
      (admin? || unit_lead? || team_lead_of?(record.user.team))
  end

  def reject?
    return false unless record
    approve?
  end

  def submit?
    return false unless record
    return false unless active_user?

    # Users can submit their own draft ratings
    return true if own_record?(record) && record.can_be_submitted?

    # Team leads can submit their team's draft ratings
    return true if team_lead? && team_lead_of?(record.user.team) && record.can_be_submitted?

    # Admins and unit leads can submit any draft rating
    return true if (admin? || unit_lead?) && record.can_be_submitted?

    false
  end

  def edit?
    return false unless record
    update?
  end

  def new?
    return false unless active_user?

    return true if record.nil? || own_record?(record)

    admin?
  end

  def copy_from_previous?
    return false unless record
    active_user? && (admin? || unit_lead? || team_lead?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      return scope.none unless user

      if user.admin? || user.unit_lead?
        scope.all
      elsif user.team_lead?
        scope.where(team_id: user.team_id)
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
