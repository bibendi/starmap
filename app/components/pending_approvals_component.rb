# frozen_string_literal: true

class PendingApprovalsComponent < ViewComponent::Base
  attr_reader :users, :current_user

  def initialize(users:, current_user:)
    @users = users
    @current_user = current_user
  end

  def render?
    users.any?
  end
end
