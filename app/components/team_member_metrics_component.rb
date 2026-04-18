# frozen_string_literal: true

class TeamMemberMetricsComponent < ViewComponent::Base
  attr_reader :team, :team_member_metrics, :team_members

  def initialize(team:, team_members:, team_member_metrics:)
    @team = team
    @team_members = team_members
    @team_member_metrics = team_member_metrics
  end

  def any_data?
    return false unless @team_members.any?

    @team_member_metrics.values.any? do |metrics|
      metrics.values.any? do |metric|
        metric.values.any?(&:positive?)
      end
    end
  end
end
