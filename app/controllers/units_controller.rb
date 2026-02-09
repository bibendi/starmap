class UnitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_unit, :set_unit_context, only: [:show]

  skip_after_action :verify_policy_scoped

  def index
    @units = policy_scope(Unit).includes(:unit_lead).ordered.page(params[:page]).per(20)
    authorize Unit
  end

  def show
  end

  private

  def set_unit
    @unit = if params[:name].present?
      Unit.find_by!(name: params[:name])
    elsif current_user.unit.present?
      current_user.unit
    else
      redirect_to units_path and return
    end
    authorize @unit
  end

  def set_unit_context
    @current_quarter = Quarter.current
    @teams = @unit.teams.includes(:team_lead, :users, :team_technologies)
  end
end
