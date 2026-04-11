module Admin
  class TechnologiesController < BaseController
    PER_PAGE = 25

    before_action :set_technology, only: [:show, :edit, :update, :destroy]

    def index
      authorize [:admin, Technology]
      @technologies = policy_scope([:admin, Technology]).includes(:category)
      @technologies = filter_by_active(@technologies)
      @technologies = filter_by_name(@technologies)
      @technologies = filter_by_category(@technologies)
      @technologies = sort(@technologies)
      @technologies = @technologies.page(params[:page]).per(PER_PAGE)
    end

    def show
      authorize [:admin, @technology]
    end

    def new
      authorize [:admin, Technology]
      @technology = Technology.new
    end

    def create
      authorize [:admin, Technology]
      @technology = Technology.new(technology_params)
      @technology.created_by = current_user

      if @technology.save
        redirect_to admin_technology_path(@technology), notice: t("admin.technologies.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize [:admin, @technology]
    end

    def update
      authorize [:admin, @technology]

      if @technology.update(technology_params.merge(updated_by: current_user))
        redirect_to admin_technology_path(@technology), notice: t("admin.technologies.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      authorize [:admin, @technology]
      if @technology.destroy
        redirect_to admin_technologies_path, notice: t("admin.technologies.destroyed")
      else
        redirect_to admin_technologies_path, alert: t("admin.technologies.cannot_delete_with_dependencies")
      end
    end

    def reorder
      authorize [:admin, Technology], :index?

      if request.patch?
        ids = params[:ids]

        if ids.blank?
          return head :unprocessable_content
        end

        Technology.transaction do
          ids.each_with_index do |id, index|
            Technology.where(id: id).update_all(sort_order: index)
          end
        end

        redirect_to admin_technologies_path, notice: t("admin.technologies.saved_order")
      else
        @technologies = Technology.ordered.includes(:category)
      end
    end

    private

    def set_technology
      @technology = Technology.find(params[:id])
    end

    def technology_params
      params.require(:technology).permit(
        :name,
        :description,
        :category_id,
        :criticality,
        :target_experts,
        :active
      )
    end

    def filter_by_active(scope)
      return scope if params[:active].blank?
      scope.where(active: params[:active])
    end

    def filter_by_name(scope)
      return scope if params[:name].blank?
      scope.where("name ILIKE ?", "%#{params[:name]}%")
    end

    def filter_by_category(scope)
      return scope if params[:category_id].blank?
      scope.where(category_id: params[:category_id])
    end

    def sort(scope)
      scope.order(sort_order: :asc, name: :asc)
    end
  end
end
