class TeamsController < ApplicationController
  include ExpertConstants

  before_action :authenticate_user!
  before_action :set_team, :set_team_context

  # Skip policy scope verification as we use explicit authorization
  skip_after_action :verify_policy_scoped

  def show
    @technologies = team_technologies.order(:name)
    @technology_counts = technology_counts_by_criticality
    @team_member_metrics = calculate_team_member_metrics
  end

  private

  # Callbacks to set up team context
  def set_team
    @team = if params[:name].present?
              Team.find_by!(name: params[:name])
            else
              current_user.team || Team.new
            end
    authorize @team
  end

  def set_team_context
    @current_quarter = Quarter.current
    @team_members = @team&.users || []
  end

  # Helper methods to reduce duplication
  def team_technologies
    @team.technologies.order(:name)
  end

  def team_technology_for(technology)
    @team.team_technologies.find_by(technology_id: technology.id)
  end



  def technology_counts_by_criticality
    @team.team_technologies
      .group(:criticality)
      .count
      .transform_keys(&:to_sym)
      .then { |counts| { high: counts[:high] || 0, normal: counts[:normal] || 0, low: counts[:low] || 0 } }
  end

  def calculate_team_member_metrics
    metrics = {}

    @team_members.each do |user|
      metrics[user.id] = {
        competence_level: { total: 0, high: 0, normal: 0, low: 0 },
        universality: { total: 0, high: 0, normal: 0, low: 0 },
        expertise_concentration: { total: 0, high: 0, normal: 0, low: 0 }
      }
    end

    team_ratings = SkillRating
      .joins(:technology)
      .joins("LEFT JOIN team_technologies ON team_technologies.team_id = skill_ratings.team_id AND team_technologies.technology_id = skill_ratings.technology_id")
      .where(team_id: @team.id, quarter_id: @current_quarter.id, technologies: { active: true })
      .select(
        'skill_ratings.*',
        'COALESCE(team_technologies.criticality, technologies.criticality) as effective_criticality'
      )

    experts_by_tech = team_ratings
      .select { |r| r.rating >= EXPERT_MIN_RATING }
      .group_by(&:technology_id)
      .transform_values { |ratings| ratings.map(&:user_id).uniq.count }

    team_ratings.each do |rating|
      next unless metrics[rating.user_id]

      criticality = rating.effective_criticality || 'normal'
      user_metrics = metrics[rating.user_id]

      user_metrics[:competence_level][:total] += rating.rating
      user_metrics[:competence_level][criticality.to_sym] += rating.rating

      if rating.rating > 1
        user_metrics[:universality][:total] += 1
        user_metrics[:universality][criticality.to_sym] += 1
      end

      if rating.rating >= EXPERT_MIN_RATING && experts_by_tech[rating.technology_id] == 1
        user_metrics[:expertise_concentration][:total] += 1
        user_metrics[:expertise_concentration][criticality.to_sym] += 1
      end
    end

    previous_quarter = @current_quarter.previous_quarter
    if previous_quarter
      previous_metrics = calculate_quarter_metrics(previous_quarter)

      metrics.each do |user_id, user_data|
        prev_data = previous_metrics[user_id]

        if prev_data
          [:competence_level, :universality, :expertise_concentration].each do |metric_type|
            [:total, :high, :normal, :low].each do |criticality|
              current_value = user_data[metric_type][criticality]
              previous_value = prev_data[metric_type][criticality]
              user_data[metric_type]["#{criticality}_change".to_sym] = current_value - previous_value
            end
          end
        end
      end
    end

    metrics
  end

  def calculate_quarter_metrics(quarter)
    metrics = {}

    @team_members.each do |user|
      metrics[user.id] = {
        competence_level: { total: 0, high: 0, normal: 0, low: 0 },
        universality: { total: 0, high: 0, normal: 0, low: 0 },
        expertise_concentration: { total: 0, high: 0, normal: 0, low: 0 }
      }
    end

    team_ratings = SkillRating
      .joins(:technology)
      .joins("LEFT JOIN team_technologies ON team_technologies.team_id = skill_ratings.team_id AND team_technologies.technology_id = skill_ratings.technology_id")
      .where(team_id: @team.id, quarter_id: quarter.id, technologies: { active: true })
      .select(
        'skill_ratings.*',
        'COALESCE(team_technologies.criticality, technologies.criticality) as effective_criticality'
      )

    experts_by_tech = team_ratings
      .select { |r| r.rating >= EXPERT_MIN_RATING }
      .group_by(&:technology_id)
      .transform_values { |ratings| ratings.map(&:user_id).uniq.count }

    team_ratings.each do |rating|
      next unless metrics[rating.user_id]

      criticality = rating.effective_criticality || 'normal'
      user_metrics = metrics[rating.user_id]

      user_metrics[:competence_level][:total] += rating.rating
      user_metrics[:competence_level][criticality.to_sym] += rating.rating

      if rating.rating > 1
        user_metrics[:universality][:total] += 1
        user_metrics[:universality][criticality.to_sym] += 1
      end

      if rating.rating >= EXPERT_MIN_RATING && experts_by_tech[rating.technology_id] == 1
        user_metrics[:expertise_concentration][:total] += 1
        user_metrics[:expertise_concentration][criticality.to_sym] += 1
      end
    end

    metrics
  end
end
