# frozen_string_literal: true

class McpController < ApplicationController
  include ApiClientAuthenticatable

  skip_forgery_protection
  skip_after_action :verify_authorized, :verify_policy_scoped
  before_action -> { request.format = :json }
  before_action :authenticate_any!

  def create
    server = build_mcp_server
    response = server.handle_json(request.body.read)
    render json: response
  end

  private

  def authenticate_any!
    return if user_signed_in?
    return if try_bearer_auth

    render json: {error: "Unauthorized"}, status: :unauthorized
  end

  def try_bearer_auth
    return false unless request.authorization.to_s.start_with?("Bearer ")

    warden.authenticate(:bearer_token, scope: :user) ||
      warden.authenticate(:api_client_token, scope: :api_client)
  end

  def current_identity
    current_user || current_api_client
  end

  def build_mcp_server
    MCP::Server.new(
      name: "starmap",
      version: "1.0.0",
      tools: [TeamMetricsTool],
      server_context: {current_identity: current_identity}
    )
  end
end
