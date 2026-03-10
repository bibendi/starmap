module Admin
  class QuartersController < BaseController
    PER_PAGE = 25

    def index
      authorize [:admin, Quarter]
      @quarters = policy_scope([:admin, Quarter])
      @quarters = filter_by_status(@quarters)
      @quarters = @quarters.order(year: :desc, quarter_number: :desc)
      @quarters = @quarters.page(params[:page]).per(PER_PAGE)
    end

    def activate
      @quarter = Quarter.find(params[:id])
      authorize [:admin, @quarter]

      service = QuarterStatusService.new(@quarter, current_user)

      if service.activate
        redirect_to admin_quarters_path, notice: t("admin.quarters.activated")
      else
        redirect_to admin_quarters_path, alert: service.errors.join(", ")
      end
    end

    def close
      @quarter = Quarter.find(params[:id])
      authorize [:admin, @quarter]

      service = QuarterStatusService.new(@quarter, current_user)

      if service.close
        redirect_to admin_quarters_path, notice: t("admin.quarters.closed")
      else
        redirect_to admin_quarters_path, alert: service.errors.join(", ")
      end
    end

    def archive
      @quarter = Quarter.find(params[:id])
      authorize [:admin, @quarter]

      service = QuarterStatusService.new(@quarter, current_user)

      if service.archive
        redirect_to admin_quarters_path, notice: t("admin.quarters.archived")
      else
        redirect_to admin_quarters_path, alert: service.errors.join(", ")
      end
    end

    def destroy
      @quarter = Quarter.find(params[:id])
      authorize [:admin, @quarter]

      if @quarter.draft?
        @quarter.destroy
        redirect_to admin_quarters_path, notice: t("admin.quarters.destroyed")
      else
        redirect_to admin_quarters_path, alert: t("admin.quarters.errors.cannot_delete_non_draft")
      end
    end

    private

    def filter_by_status(scope)
      return scope if params[:status].blank?
      return scope unless Quarter.statuses.key?(params[:status])

      scope.where(status: params[:status])
    end
  end
end
