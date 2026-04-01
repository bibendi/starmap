class Admin::TeamPolicy < Admin::BasePolicy
  def show?
    can_manage? && (admin? || unit_lead_owns_record?)
  end

  def edit?
    can_manage? && (admin? || unit_lead_owns_record?)
  end

  def update?
    can_manage? && (admin? || unit_lead_owns_record?)
  end

  def destroy?
    can_manage? && (admin? || unit_lead_owns_record?)
  end

  def permitted_attributes_for_create
    base_permitted_attributes
  end

  def permitted_attributes_for_edit
    base_permitted_attributes
  end

  def permitted_attributes
    base_permitted_attributes
  end

  private

  def can_manage?
    admin? || unit_lead?
  end

  def unit_lead_owns_record?
    return false unless unit_lead?

    team_record.unit_id == user.unit&.id
  end

  def team_record
    record.is_a?(Array) ? record.last : record
  end

  def base_permitted_attributes
    attrs = [:name, :description, :active, :team_lead_id, {member_ids: []}]
    attrs << :unit_id if admin?
    attrs
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if can_manage?
        unit_lead? ? scope.by_unit(user.unit) : scope.all
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
