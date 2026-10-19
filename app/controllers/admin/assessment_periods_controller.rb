module Admin
  class AssessmentPeriodsController < BaseController
    PER_PAGE = 25

    def index
      authorize [:admin, AssessmentPeriod]
      @assessment_periods = policy_scope([:admin, AssessmentPeriod])
      @assessment_periods = filter_by_status(@assessment_periods)
      @assessment_periods = @assessment_periods.order(start_date: :desc)
      @assessment_periods = @assessment_periods.page(params[:page]).per(PER_PAGE)
    end

    def new
      authorize [:admin, AssessmentPeriod]
      start_date = Date.current.beginning_of_quarter.prev_quarter
      @assessment_period = AssessmentPeriod.new(start_date: start_date, end_date: start_date.end_of_quarter)
    end

    def create
      authorize [:admin, AssessmentPeriod]
      @assessment_period = AssessmentPeriod.new(assessment_period_params)
      @assessment_period.created_by = current_user

      if @assessment_period.save
        redirect_to admin_assessment_periods_path, notice: t("admin.assessment_periods.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def activate
      @assessment_period = AssessmentPeriod.find(params[:id])
      authorize [:admin, @assessment_period]

      service = AssessmentPeriodStatusService.new(@assessment_period, current_user)

      if service.activate
        redirect_to admin_assessment_periods_path, notice: t("admin.assessment_periods.activated")
      else
        redirect_to admin_assessment_periods_path, alert: service.errors.join(", ")
      end
    end

    def close
      @assessment_period = AssessmentPeriod.find(params[:id])
      authorize [:admin, @assessment_period]

      service = AssessmentPeriodStatusService.new(@assessment_period, current_user)

      if service.close
        redirect_to admin_assessment_periods_path, notice: t("admin.assessment_periods.closed")
      else
        redirect_to admin_assessment_periods_path, alert: service.errors.join(", ")
      end
    end

    def archive
      @assessment_period = AssessmentPeriod.find(params[:id])
      authorize [:admin, @assessment_period]

      service = AssessmentPeriodStatusService.new(@assessment_period, current_user)

      if service.archive
        redirect_to admin_assessment_periods_path, notice: t("admin.assessment_periods.archived")
      else
        redirect_to admin_assessment_periods_path, alert: service.errors.join(", ")
      end
    end

    def show
      @assessment_period = AssessmentPeriod.find(params[:id])
      authorize [:admin, @assessment_period]
      load_assessment_period_metrics
    end

    def edit
      @assessment_period = AssessmentPeriod.find(params[:id])
      authorize [:admin, @assessment_period]
    end

    def update
      @assessment_period = AssessmentPeriod.find(params[:id])
      authorize [:admin, @assessment_period]

      if @assessment_period.draft?
        if @assessment_period.update(assessment_period_params)
          redirect_to admin_assessment_period_path(@assessment_period), notice: t("admin.assessment_periods.updated")
        else
          render :edit, status: :unprocessable_content
        end
      else
        redirect_to admin_assessment_period_path(@assessment_period), alert: t("admin.assessment_periods.errors.cannot_edit_non_draft")
      end
    end

    def destroy
      @assessment_period = AssessmentPeriod.find(params[:id])
      authorize [:admin, @assessment_period]

      if @assessment_period.draft?
        @assessment_period.destroy
        redirect_to admin_assessment_periods_path, notice: t("admin.assessment_periods.destroyed")
      else
        redirect_to admin_assessment_periods_path, alert: t("admin.assessment_periods.errors.cannot_delete_non_draft")
      end
    end

    rescue_from ActiveRecord::StatementInvalid, with: :handle_constraint_conflict

    private

    def handle_constraint_conflict(error)
      raise error unless error.cause.is_a?(PG::ExclusionViolation)

      @assessment_period.errors.add(:base, :overlap)
      render (action_name == "create") ? :new : :edit, status: :unprocessable_content
    end

    def assessment_period_params
      params.require(:assessment_period).permit(
        :period_kind, :calendar_year, :calendar_number,
        :start_date, :end_date,
        :evaluation_start_date, :evaluation_end_date,
        :description
      )
    end

    def load_assessment_period_metrics
      @skill_ratings_count = @assessment_period.skill_ratings.count
      @approved_ratings_count = @assessment_period.skill_ratings.where(status: :approved).count
      @users_with_ratings = @assessment_period.skill_ratings.where(status: :approved).distinct.count(:user_id)
    end

    def filter_by_status(scope)
      return scope if params[:status].blank?
      return scope unless AssessmentPeriod.statuses.key?(params[:status])

      scope.where(status: params[:status])
    end
  end
end
