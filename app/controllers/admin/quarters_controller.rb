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

    def new
      authorize [:admin, Quarter]
      @quarter = Quarter.new
      set_default_year_and_quarter
    end

    def create
      authorize [:admin, Quarter]
      @quarter = Quarter.new(quarter_params)
      @quarter.created_by = current_user

      if @quarter.save
        redirect_to admin_quarters_path, notice: t("admin.quarters.created")
      else
        render :new, status: :unprocessable_content
      end
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

    def show
      @quarter = Quarter.find(params[:id])
      authorize [:admin, @quarter]
      load_quarter_metrics
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

    def quarter_params
      params.require(:quarter).permit(
        :year, :quarter_number,
        :start_date, :end_date,
        :evaluation_start_date, :evaluation_end_date,
        :description
      )
    end

    def set_default_year_and_quarter
      current_year = Date.current.year
      existing_quarters = Quarter.where(year: current_year).pluck(:quarter_number)
      available_quarter = (1..4).find { |q| !existing_quarters.include?(q) }

      @quarter.year = current_year
      @quarter.quarter_number = available_quarter || 1
    end

    def load_quarter_metrics
      @skill_ratings_count = @quarter.skill_ratings.count
      @action_plans_count = @quarter.action_plans.count
      @users_with_ratings = @quarter.skill_ratings.distinct.count(:user_id)
    end

    def filter_by_status(scope)
      return scope if params[:status].blank?
      return scope unless Quarter.statuses.key?(params[:status])

      scope.where(status: params[:status])
    end
  end
end
