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

    private

    def filter_by_status(scope)
      return scope if params[:status].blank?
      return scope unless Quarter.statuses.key?(params[:status])

      scope.where(status: params[:status])
    end
  end
end
