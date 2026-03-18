module Admin
  class BaseController < ApplicationController
    before_action :authenticate_user!
    skip_after_action :verify_policy_scoped
    layout "admin"

    rescue_from ActiveRecord::RecordNotFound, with: :not_found

    private

    def not_found
      head :not_found
    end
  end
end
