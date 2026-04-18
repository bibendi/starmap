# frozen_string_literal: true

class UnitTechnologyTreemapComponent < ViewComponent::Base
  attr_reader :technologies_data, :teams, :max_experts, :max_deficit

  def initialize(teams:, technologies_data:)
    @teams = teams
    @technologies_data = technologies_data
    @max_experts = max_value(:expert_count)
    @max_deficit = max_value(:deficit)
  end

  def any_technologies?
    technologies_data.any?
  end

  def technologies_count
    technologies_data.size
  end

  def intensity_for_experts(count)
    return 1 if max_experts <= 1
    normalized = (count.to_f / max_experts * 4).round + 1
    [normalized, 5].min
  end

  def intensity_for_deficit(deficit)
    return 1 if max_deficit <= 1
    normalized = (deficit.to_f / max_deficit * 4).round + 1
    [normalized, 5].min
  end

  def chart_data
    technologies_data.map do |tech|
      {
        name: tech[:technology]&.name,
        category: tech[:technology]&.category&.name,
        value: tech[:expert_count],
        allTeamsInTarget: tech[:all_teams_in_target],
        intensity: intensity_for_experts(tech[:expert_count]),
        deficitIntensity: intensity_for_deficit(tech[:deficit])
      }
    end
  end

  private

  def max_value(key)
    [@technologies_data.pluck(key).max, 1].compact.max
  end
end
