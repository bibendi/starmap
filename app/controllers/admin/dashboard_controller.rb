module Admin
  class DashboardController < BaseController
    skip_after_action :verify_authorized

    def index
      redirect_to admin_quarters_path
    end
  end
end
