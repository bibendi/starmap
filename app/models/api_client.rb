# frozen_string_literal: true

class ApiClient < ApplicationRecord
  AVAILABLE_PERMISSIONS = %w[teams:read units:read].freeze

  validates :name, :oidc_client_id, presence: true
  validates :oidc_client_id, uniqueness: true
  validates :permissions, inclusion: {in: -> { AVAILABLE_PERMISSIONS }, message: "%{value} is not a valid permission"}
  validates :team_ids, presence: true, if: :any_read_permission?

  scope :enabled, -> { where(enabled: true) }

  def accessible_teams
    Team.where(id: team_ids)
  end

  def can_access_team?(team)
    team_ids.include?(team.id)
  end

  def has_permission?(permission)
    permissions.include?(permission)
  end

  private

  def any_read_permission?
    permissions.intersect?(AVAILABLE_PERMISSIONS)
  end
end
