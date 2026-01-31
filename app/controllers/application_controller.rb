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

  helper_method :current_locale, :available_locales
  helper_method :current_theme, :theme_class

  private

  def set_locale
    I18n.locale = locale_from_cookies || locale_from_browser || I18n.default_locale
  end

  def locale_from_cookies
    locale = cookies[:locale]&.to_sym
    locale if I18n.available_locales.include?(locale)
  end

  def locale_from_browser
    http_accept_language = request.headers["Accept-Language"]
    return unless http_accept_language

    # Parse Accept-Language header: "en-US,en;q=0.9,ru;q=0.8"
    browser_locales = http_accept_language.scan(/[a-z]{2}(?:-[A-Z]{2})?/).map do |lang|
      lang[0..1].to_sym  # Take first 2 chars (primary language)
    end.uniq

    browser_locales.find { |locale| I18n.available_locales.include?(locale) }
  end

  def current_locale
    I18n.locale
  end

  def available_locales
    I18n.available_locales
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || team_path
  end

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end

  def current_theme
    theme = cookies[:theme]&.to_sym
    theme if %i[light dark system].include?(theme)
  end

  def theme_class
    return "dark" if current_theme == :dark
    ""
  end
end
