class ThemesController < ApplicationController
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def switch
    theme = params[:theme]&.to_sym
    if %i[light dark system].include?(theme)
      cookies[:theme] = {value: theme, path: "/", expires: 1.year.from_now}
      flash[:notice] = t("theme.switched.#{theme}")
    end
    redirect_back_or_to(root_path)
  end
end
