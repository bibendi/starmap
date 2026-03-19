class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  before_action :set_current_quarter
  skip_after_action :verify_policy_scoped

  def show
    authorize @user
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def set_current_quarter
    @current_quarter = Quarter.current
  end
end
