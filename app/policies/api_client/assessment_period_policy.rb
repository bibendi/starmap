# frozen_string_literal: true

class ApiClient::AssessmentPeriodPolicy < ApiClient::ApplicationPolicy
  def index?
    enabled? && has_permission?("teams:read")
  end
end
