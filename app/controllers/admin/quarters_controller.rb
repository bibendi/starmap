module Admin
  class QuartersController < BaseController
    def index
      authorize Quarter
      @quarters = policy_scope(Quarter).order(year: :desc, quarter_number: :desc).page(params[:page]).per(25)
    end
  end
end
