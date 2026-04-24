# frozen_string_literal: true

class McpController < ApplicationController
  skip_forgery_protection
  skip_after_action :verify_authorized, :verify_policy_scoped
  before_action -> { request.format = :json }
  before_action :authenticate_user!

  def create
    server = build_mcp_server
    response = server.handle_json(request.body.read)
    render json: response
  end

  private

  def build_mcp_server
    MCP::Server.new(
      name: "starmap",
      version: "1.0.0",
      tools: [TeamMetricsTool],
      server_context: {current_user: current_user}
    )
  end
end
