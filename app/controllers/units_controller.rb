class UnitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_unit, :set_unit_context

  skip_after_action :verify_policy_scoped

  def show
  end

  private

  def set_unit
    @unit = if params[:name].present?
      Unit.find_by!(name: params[:name])
    else
      current_user.unit || Unit.new
    end
    authorize @unit
  end

  def set_unit_context
    @current_quarter = Quarter.current
  end
end
