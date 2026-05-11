# frozen_string_literal: true

class ApiClient::ApplicationPolicy
  attr_reader :api_client, :record

  def initialize(api_client, record)
    @api_client = api_client
    @record = record
  end

  private

  def has_permission?(perm)
    api_client.has_permission?(perm)
  end

  def can_access_team?(team)
    api_client.can_access_team?(team)
  end

  def enabled?
    api_client.enabled?
  end
end
