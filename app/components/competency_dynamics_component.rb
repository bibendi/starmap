# frozen_string_literal: true

class CompetencyDynamicsComponent < ViewComponent::Base
  attr_reader :competency_dynamics, :team_members

  def initialize(competency_dynamics:, team_members:)
    @competency_dynamics = competency_dynamics
    @team_members = team_members
  end
end
