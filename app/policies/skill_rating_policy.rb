# SkillRating policy for role-based access control
class SkillRatingPolicy < ApplicationPolicy
  def index?
    user&.active?
  end

  def show?
    return false unless user&.active?

    # Users can see their own ratings
    return true if own_record?(record)

    # Admins and unit leads can see all ratings
    return true if user.admin? || user.unit_lead?

    # Team leads can see their team's ratings
    return user.team_lead_of?(record.user.team) if user.team_lead?

    # Engineers can see aggregated data for overview dashboard
    return true if user.engineer? && record.user != user

    false
  end

  def create?
    return false unless user&.active?

    # Users can create ratings for themselves
    return true if own_record?(record)

    # Team leads can create ratings for their team members
    return user.team_lead_of?(record.user.team) if user.team_lead?

    false
  end

  def update?
    return false unless user&.active?

    # Users can update their own ratings if not approved
    return true if own_record?(record) && !record.approved?

    # Team leads can update their team's ratings
    return user.team_lead_of?(record.user.team) if user.team_lead?

    # Admins and unit leads can update any rating
    return true if user.admin? || user.unit_lead?

    false
  end

  def destroy?
    user&.admin?
  end

  def approve?
    user&.can_approve_skill_ratings? &&
    (user.admin? || user.unit_lead? || user.team_lead_of?(record.user.team))
  end

  def reject?
    approve?
  end

  def edit?
    update?
  end

  def new?
    create?
  end

  def copy_from_previous?
    user&.active? && (user.admin? || user.unit_lead? || user.team_lead?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.unit_lead?
        scope.all
      elsif user.team_lead?
        scope.joins(:user).where(users: { team_id: user.team_id })
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
