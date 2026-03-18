module Admin
  class UsersController < BaseController
    skip_after_action :verify_authorized

    def index
    end
  end
end
