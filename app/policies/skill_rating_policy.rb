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

    # Engineers can see aggregated data for overview dashboard
    return true if engineer? && record.user != user

    false
  end

  def create?
    return false unless active_user?

    # Users can create ratings for themselves
    return true if own_record?(record)

    # Team leads can create ratings for their team members
    return team_lead_of?(record.user.team) if team_lead?

    false
  end

  def update?
    return false unless active_user?

    # Users can update their own ratings if not approved
    return true if own_record?(record) && !record.approved?

    # Team leads can update their team's ratings
    return team_lead_of?(record.user.team) if team_lead?

    # Admins and unit leads can update any rating
    return true if admin? || unit_lead?

    false
  end

  def destroy?
    admin?
  end

  def approve?
    (team_lead? || unit_lead? || admin?) &&
    (admin? || unit_lead? || team_lead_of?(record.user.team))
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
    active_user? && (admin? || unit_lead? || team_lead?)
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if admin? || unit_lead?
        scope.all
      elsif team_lead?
        scope.joins(:user).where(users: { team_id: user.team_id })
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
