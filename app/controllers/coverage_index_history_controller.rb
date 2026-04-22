# frozen_string_literal: true

class CoverageIndexHistoryController < ApplicationController
  skip_after_action :verify_policy_scoped
  before_action :authenticate_user!

  def index
    teams = find_teams
    if teams.empty?
      skip_authorization
      return render json: {error: "team_ids parameter is required"}, status: :bad_request
    end

    authorize teams, policy_class: CoverageIndexHistoryPolicy

    render json: {history: CoverageIndexHistoryQuery.new(teams: teams).data}
  end

  private

  def find_teams
    ids = Array(params[:team_ids]).compact_blank.map(&:to_i)
    return Team.none if ids.empty?

    Team.where(id: ids)
  end
end
