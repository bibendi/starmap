class EngineersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user
  skip_after_action :verify_policy_scoped

  def show
    authorize @user, policy_class: EngineerPolicy
  end

  private

  def set_user
    @user = if params[:id].present?
      User.find(params[:id])
    else
      current_user
    end
  end
end
