class LocalesController < ApplicationController
  # Skip authorization for locale switching
  skip_after_action :verify_authorized
  skip_after_action :verify_policy_scoped

  def switch
    locale = params[:locale]&.to_sym
    if I18n.available_locales.include?(locale)
      cookies[:locale] = {value: locale, expires: 1.year.from_now}
      language_name = I18n.t("locale.names.#{locale}", default: locale.to_s, locale: locale)
      flash[:notice] = I18n.t("locale.switched", language: language_name, locale: locale)
    end
    redirect_back_or_to(root_path)
  end
end
