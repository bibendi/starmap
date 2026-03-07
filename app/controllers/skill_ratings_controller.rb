# frozen_string_literal: true

# SkillRatingsController for managing skill ratings
# Allows engineers and team leads to fill in skill ratings during evaluation periods
class SkillRatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_target_user
  before_action :set_current_quarter
  before_action :ensure_evaluation_period, only: [:edit, :update]
  before_action :ensure_team_assignment
  before_action :set_team_technologies, only: [:show, :edit, :update]
  before_action :set_skill_ratings, only: [:show, :edit, :update]

  skip_after_action :verify_policy_scoped

  def show
    authorize_skill_ratings
  end

  def edit
    authorize_skill_ratings
  end

  def update
    authorize_skill_ratings

    if update_skill_ratings
      redirect_to user_skill_ratings_path(@target_user),
        notice: t("skill_ratings.update.success")
    else
      set_team_technologies
      set_skill_ratings
      render :edit, status: :unprocessable_content
    end
  end

  private

  def set_target_user
    @target_user = if params[:user_id].present?
      User.find(params[:user_id])
    else
      current_user
    end
  end

  def set_current_quarter
    @current_quarter = Quarter.current
  end

  def ensure_evaluation_period
    return if @current_quarter&.evaluation_period?

    redirect_to engineer_path(id: @target_user.id),
      alert: t("skill_ratings.errors.not_evaluation_period")
  end

  def ensure_team_assignment
    return if @target_user.team.present?

    redirect_to engineer_path(id: @target_user.id),
      alert: t("skill_ratings.errors.no_team")
  end

  def set_team_technologies
    return unless @target_user.team

    @team_technologies = @target_user.team.team_technologies
      .includes(:technology)
      .joins(:technology)
      .where(technologies: {active: true})
      .order("technologies.sort_order, technologies.name")
  end

  def set_skill_ratings
    @skill_ratings_data = []
    return unless @current_quarter && @team_technologies

    existing_ratings = SkillRating.by_user(@target_user)
      .by_quarter(@current_quarter)
      .index_by(&:technology_id)

    @skill_ratings_data = @team_technologies.map do |team_tech|
      technology = team_tech.technology
      rating = existing_ratings[technology.id]

      {
        team_technology: team_tech,
        technology: technology,
        skill_rating: rating || SkillRating.new(
          user: @target_user,
          technology: technology,
          quarter: @current_quarter,
          rating: 0,
          status: "draft",
          team: @target_user.team
        )
      }
    end
  end

  def authorize_skill_ratings
    rating = @skill_ratings_data.first&.[](:skill_rating) ||
      SkillRating.new(user: @target_user, quarter: @current_quarter)
    authorize rating
  end

  def update_skill_ratings
    return false if skill_ratings_params[:ratings].blank?

    ActiveRecord::Base.transaction do
      skill_ratings_params[:ratings].each do |technology_id, rating_data|
        update_or_create_rating(technology_id, rating_data)
      end
    end

    true
  rescue ActiveRecord::RecordInvalid
    false
  end

  def update_or_create_rating(technology_id, rating_data)
    technology = Technology.find(technology_id)
    rating_value = rating_data[:rating].to_i

    skill_rating = SkillRating.find_or_initialize_by(
      user: @target_user,
      technology: technology,
      quarter: @current_quarter
    )

    # Only set created_by and team_id for new records to preserve history
    if skill_rating.new_record?
      skill_rating.created_by = current_user
      skill_rating.team_id = @target_user.team_id
    end

    skill_rating.assign_attributes(
      rating: rating_value,
      status: "draft",
      updated_by: current_user
    )

    skill_rating.save!
  end

  def skill_ratings_params
    params.permit(ratings: [:rating, :comment])
  end
end
