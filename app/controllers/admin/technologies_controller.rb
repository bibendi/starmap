module Admin
  class TechnologiesController < BaseController
    skip_after_action :verify_authorized

    def index
    end
  end
end
