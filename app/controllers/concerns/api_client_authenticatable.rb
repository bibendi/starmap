# frozen_string_literal: true

module ApiClientAuthenticatable
  extend ActiveSupport::Concern

  included do
    helper_method :current_api_client, :api_client_authenticated?
  end

  private

  def current_api_client
    warden.user(:api_client)
  end

  def api_client_authenticated?
    current_api_client.present?
  end
end
