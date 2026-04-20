# frozen_string_literal: true

# SkillRatingsController for managing skill ratings
# Allows engineers and team leads to fill in skill ratings during evaluation periods
class SkillRatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_target_user
  before_action :set_current_quarter
  before_action :ensure_evaluation_period, only: [:edit, :update, :submit]
  before_action :ensure_team_assignment
  before_action :set_team_technologies, only: [:show, :edit, :update, :submit, :approve, :reject]
  before_action :set_skill_ratings, only: [:show, :edit, :update, :submit, :approve, :reject]
  before_action :set_skill_rating, only: [:approve, :reject]

  skip_after_action :verify_policy_scoped

  def show
    authorize_skill_ratings
    set_can_approve_any
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

  def submit
    authorize_skill_ratings

    if @skill_ratings_data.any? { |d| d[:skill_rating].rejected? }
      return redirect_to user_skill_ratings_path(@target_user),
        alert: t("skill_ratings.submit.has_rejected")
    end

    draft_ratings = @skill_ratings_data
      .map { |d| d[:skill_rating] }
      .select { |r| r.persisted? && r.draft? }

    if draft_ratings.empty?
      return redirect_to user_skill_ratings_path(@target_user),
        alert: t("skill_ratings.submit.no_drafts")
    end

    draft_ratings.each { |r| r.submit_for_approval }

    redirect_to user_skill_ratings_path(@target_user),
      notice: t("skill_ratings.submit.success")
  end

  def approve
    authorize @skill_rating
    @skill_rating.approve!(current_user)
    set_skill_ratings
    set_can_approve_any

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to user_skill_ratings_path(@target_user), notice: t("skill_ratings.approve.success") }
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to user_skill_ratings_path(@target_user),
      alert: t("skill_ratings.approve.already_processed")
  end

  def reject
    authorize @skill_rating
    @skill_rating.reject!(current_user)
    set_skill_ratings
    set_can_approve_any

    respond_to do |format|
      format.turbo_stream
      format.html { redirect_to user_skill_ratings_path(@target_user), notice: t("skill_ratings.reject.success") }
    end
  rescue ActiveRecord::RecordInvalid
    redirect_to user_skill_ratings_path(@target_user),
      alert: t("skill_ratings.approve.already_processed")
  end

  def approve_all
    authorize SkillRating.new(user: @target_user, quarter: @current_quarter), :approve?

    submitted_ratings = find_submitted_ratings

    if submitted_ratings.empty?
      return redirect_to user_skill_ratings_path(@target_user),
        alert: t("skill_ratings.approve.no_submitted")
    end

    authorizeable = submitted_ratings.select { |r| policy(r).approve? }
    if authorizeable.empty?
      return redirect_to user_skill_ratings_path(@target_user),
        alert: t("skill_ratings.approve.no_submitted")
    end

    ActiveRecord::Base.transaction do
      authorizeable.each { |r| r.approve!(current_user) }
    end

    redirect_to user_skill_ratings_path(@target_user),
      notice: t("skill_ratings.approve.all_success")
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

    redirect_to user_path(@target_user),
      alert: t("skill_ratings.errors.not_evaluation_period")
  end

  def ensure_team_assignment
    return if @target_user.team.present?

    redirect_to user_path(@target_user),
      alert: t("skill_ratings.errors.no_team")
  end

  def set_team_technologies
    return unless @target_user.team

    @team_technologies = @target_user.team.team_technologies
      .active
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

    rating_changes = UserRatingChangesQuery
      .new(user: @target_user, quarter: @current_quarter)
      .changes_by_technology

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
        ),
        rating_change: rating_changes[technology.id]
      }
    end
  end

  def authorize_skill_ratings
    rating = @skill_ratings_data
      .map { |d| d[:skill_rating] }
      .find { |r| policy(r).update? } ||
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

    return if skill_rating.approved? && current_user == @target_user

    rating_changed = skill_rating.new_record? || skill_rating.rating != rating_value

    skill_rating.assign_attributes(
      rating: rating_value,
      status: rating_changed ? "draft" : skill_rating.status,
      updated_by: current_user
    )

    skill_rating.save!
  end

  def skill_ratings_params
    params.permit(ratings: [:rating, :comment])
  end

  def set_skill_rating
    @skill_rating = SkillRating.find(params[:id])
  end

  def set_can_approve_any
    @can_approve_any = @skill_ratings_data.any? { |d| policy(d[:skill_rating]).approve? }
  end

  def find_submitted_ratings
    return [] unless @current_quarter

    SkillRating.by_user(@target_user)
      .by_quarter(@current_quarter)
      .submitted
  end
end
