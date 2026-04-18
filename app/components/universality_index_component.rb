# frozen_string_literal: true

class UniversalityIndexComponent < ViewComponent::Base
  attr_reader :universality_index, :team_members

  def initialize(universality_index:, team_members:)
    @universality_index = universality_index
    @team_members = team_members
  end
end
