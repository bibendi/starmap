# frozen_string_literal: true

class KeyPersonRisksQuery
  def initialize(teams:, quarter: Quarter.current)
    @teams = teams
    @quarter = quarter
  end

  def count
    return 0 unless @quarter

    SkillRating
      .visible_for_quarter(@quarter)
      .expert_ratings
      .where(quarter: @quarter, team_id: team_ids)
      .group(:technology_id)
      .having("COUNT(DISTINCT user_id) = 1")
      .count
      .size
  end

  def details
    return [] unless @quarter

    tech_ids_with_single_expert = SkillRating
      .visible_for_quarter(@quarter)
      .expert_ratings
      .where(quarter: @quarter, team_id: team_ids)
      .group(:technology_id)
      .having("COUNT(DISTINCT user_id) = 1")
      .pluck(:technology_id)

    return [] if tech_ids_with_single_expert.empty?

    SkillRating
      .preload(:technology, :user, :team)
      .visible_for_quarter(@quarter)
      .expert_ratings
      .where(quarter: @quarter, team_id: team_ids, technology_id: tech_ids_with_single_expert)
      .map do |rating|
        {
          technology: rating.technology,
          team: rating.team,
          user: rating.user
        }
      end
      .sort_by { |risk| risk[:technology]&.name || "" }
  end

  private

  def team_ids
    @teams.map(&:id)
  end
end
