# frozen_string_literal: true

class RedZonesDetailsComponent < ViewComponent::Base
  attr_reader :red_zones_data, :teams

  def initialize(teams:, red_zones_data:)
    @teams = teams
    @red_zones_data = red_zones_data
  end

  def any_red_zones?
    red_zones_data.any?
  end

  def multiple_teams?
    @teams.size > 1
  end

  def grouped_red_zones
    return red_zones_data unless multiple_teams?

    red_zones_data.group_by { |red_zone| red_zone[:technology] }
  end

  def red_zones_technologies_count
    red_zones_data.size
  end

  def carousel_slides
    if multiple_teams?
      grouped_red_zones.map do |technology, red_zones|
        {
          technology: technology,
          red_zones: red_zones
        }
      end
    else
      red_zones_data.group_by { |rz| rz[:technology] }.map do |technology, red_zones|
        {
          technology: technology,
          red_zones: red_zones
        }
      end
    end
  end
end
