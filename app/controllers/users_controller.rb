class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_current_quarter
  skip_after_action :verify_policy_scoped

  def show
    authorize @user
    load_pending_users
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_current_quarter
    @current_quarter = Quarter.current
  end

  def load_pending_users
    @pending_users = if current_user == @user && (current_user.team_lead? || current_user.unit_lead? || current_user.admin?)
      User.users_with_pending_approvals(current_user)
    else
      User.none
    end
  end
end
