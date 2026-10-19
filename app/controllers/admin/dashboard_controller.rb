module Admin
  class DashboardController < BaseController
    skip_after_action :verify_authorized

    def index
      redirect_to admin_assessment_periods_path
    end
  end
end
