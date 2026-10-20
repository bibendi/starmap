# frozen_string_literal: true

class AssessmentPeriodPolicy < ApplicationPolicy
  def index?
    user.is_a?(User)
  end
end
