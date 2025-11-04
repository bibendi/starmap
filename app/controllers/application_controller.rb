class ApplicationController < ActionController::Base
  # Include Devise helpers
  include Devise::Controllers::Helpers

  # Include Pundit for authorization
  include Pundit::Authorization

  # Set locale
  before_action :set_locale

  # Protect from forgery
  protect_from_forgery with: :exception

  # Set current user for Pundit
  after_action :verify_authorized, unless: :devise_controller?
  after_action :verify_policy_scoped, unless: :devise_controller?

  # Helper methods
  helper_method :current_user, :user_signed_in?

  private

  def set_locale
    I18n.locale = params[:locale] || I18n.default_locale
  end

  def default_url_options
    { locale: I18n.locale }
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || dashboards_overview_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
