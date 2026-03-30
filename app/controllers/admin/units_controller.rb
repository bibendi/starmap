module Admin
  class UnitsController < BaseController
    PER_PAGE = 25

    before_action :set_unit, only: [:show, :edit, :update, :destroy]

    def index
      authorize [:admin, Unit]
      @units = policy_scope([:admin, Unit]).includes(:unit_lead)
      @units = filter_by_active(@units)
      @units = filter_by_name(@units)
      @units = @units.ordered.page(params[:page]).per(PER_PAGE)
    end

    def show
      authorize [:admin, @unit]
    end

    def new
      authorize [:admin, Unit]
      @unit = Unit.new
    end

    def create
      authorize [:admin, Unit]
      @unit = Unit.new(unit_params)

      if @unit.save
        redirect_to admin_unit_path(@unit), notice: t("admin.units.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize [:admin, @unit]
    end

    def update
      authorize [:admin, @unit]

      if @unit.update(unit_params)
        redirect_to admin_unit_path(@unit), notice: t("admin.units.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize [:admin, @unit]

      if @unit.destroy
        redirect_to admin_units_path, notice: t("admin.units.destroyed")
      else
        redirect_to admin_units_path, alert: t("admin.units.cannot_delete_with_teams")
      end
    end

    private

    def set_unit
      @unit = Unit.find(params[:id])
    end

    def unit_params
      params.require(:unit).permit(:name, :description, :active, :unit_lead_id)
    end

    def filter_by_active(scope)
      return scope if params[:active].blank?
      scope.where(active: params[:active])
    end

    def filter_by_name(scope)
      return scope if params[:name].blank?
      scope.where("name ILIKE ?", "%#{params[:name]}%")
    end
  end
end
