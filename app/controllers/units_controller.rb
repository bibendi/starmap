class UnitsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_unit, :set_unit_context, only: [:show]

  skip_after_action :verify_policy_scoped

  def index
    @units = policy_scope(Unit).includes(:unit_lead).ordered.page(params[:page]).per(20)
    authorize Unit
  end

  def show
    red_zones_query = RedZonesQuery.new(teams: @teams, assessment_period: @current_assessment_period)
    @red_zones_count = red_zones_query.count
    @red_zones_data = red_zones_query.details

    @coverage_index = CoverageIndexQuery.new(teams: @teams, assessment_period: @current_assessment_period).percentage
    @maturity_index = MaturityIndexQuery.new(teams: @teams, assessment_period: @current_assessment_period).value

    key_person_risks_query = KeyPersonRisksQuery.new(teams: @teams, assessment_period: @current_assessment_period)
    @key_person_risks_count = key_person_risks_query.count
    @key_person_risks_data = key_person_risks_query.details

    @technologies_data = UnitTechnologyTreemapQuery.new(teams: @teams, assessment_period: @current_assessment_period).data
  end

  private

  def set_unit
    @unit = if params[:id].present?
      Unit.find(params[:id])
    elsif current_user.unit.present?
      current_user.unit
    else
      redirect_to units_path and return
    end
    authorize @unit
  end

  def set_unit_context
    @current_assessment_period = AssessmentPeriod.current
    @teams = @unit.teams.includes(:team_lead, :users, :team_technologies)
  end
end
