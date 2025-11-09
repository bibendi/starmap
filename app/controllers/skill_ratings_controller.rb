# SkillRatingsController for Starmap application
# Handles CRUD operations for skill ratings with Hotwire integration
class SkillRatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_skill_rating, only: [:show, :edit, :update, :destroy, :approve, :reject]
  before_action :set_quarter, only: [:index, :new, :create, :user_ratings, :team_ratings, :technology_ratings, :pending_approvals, :copy_from_previous]
  before_action :require_active_quarter, only: [:new, :create, :edit, :update]
  before_action :authorize_skill_rating, only: [:show, :edit, :update, :destroy, :approve, :reject]
  before_action :set_available_data, only: [:new, :edit, :create, :update]

  # GET /skill_ratings
  def index
    @skill_ratings = policy_scope(SkillRating)
                    .includes(:user, :technology, :quarter)
                    .order('users.first_name ASC, technologies.name ASC')
                    .page(params[:page])

    respond_to do |format|
      format.html
      format.turbo_stream { render turbo_stream: turbo_stream.update("skill_ratings_list", partial: "skill_ratings/list") }
    end
  end

  # GET /skill_ratings/1
  def show
    @skill_rating = SkillRating.includes(:user, :technology, :quarter, :approved_by).find(params[:id])
    authorize @skill_rating
  end

  # GET /skill_ratings/new
  def new
    @skill_rating = SkillRating.new
    authorize @skill_rating

    # Pre-fill quarter if specified
    @skill_rating.quarter = @quarter if @quarter
    @skill_rating.user = current_user
  end

  # GET /skill_ratings/1/edit
  def edit
    @skill_rating = SkillRating.includes(:user, :technology, :quarter).find(params[:id])
    authorize @skill_rating

    unless @skill_rating.can_be_edited?
      redirect_to @skill_rating, alert: "Эта оценка не может быть отредактирована"
    end
  end

  # POST /skill_ratings
  def create
    @skill_rating = SkillRating.new(skill_rating_params)
    @skill_rating.created_by = current_user
    @skill_rating.quarter = @quarter || Quarter.current

    authorize @skill_rating

    if @skill_rating.save
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("flash", partial: "shared/flash", locals: { notice: "Оценка создана успешно" }),
            turbo_stream.replace("skill_rating_form", partial: "skill_ratings/form", locals: { skill_rating: SkillRating.new(quarter: @quarter) }),
            turbo_stream.append("skill_ratings_list", partial: "skill_ratings/rating_card", locals: { skill_rating: @skill_rating })
          ]
        end
        format.html { redirect_to skill_ratings_path, notice: "Оценка создана успешно" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream.update("skill_rating_form", partial: "skill_ratings/form", locals: { skill_rating: @skill_rating }) }
        format.html { render :new, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /skill_ratings/1
  def update
    @skill_rating = SkillRating.includes(:user, :technology, :quarter).find(params[:id])
    authorize @skill_rating

    if @skill_rating.update(skill_rating_params.merge(updated_by: current_user))
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("flash", partial: "shared/flash", locals: { notice: "Оценка обновлена успешно" }),
            turbo_stream.replace(@skill_rating, partial: "skill_ratings/rating_card", locals: { skill_rating: @skill_rating })
          ]
        end
        format.html { redirect_to @skill_rating, notice: "Оценка обновлена успешно" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream.update("skill_rating_form", partial: "skill_ratings/form", locals: { skill_rating: @skill_rating }) }
        format.html { render :edit, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /skill_ratings/1
  def destroy
    @skill_rating = SkillRating.find(params[:id])
    authorize @skill_rating

    @skill_rating.destroy
    respond_to do |format|
      format.turbo_stream { render turbo_stream.remove(@skill_rating) }
      format.html { redirect_to skill_ratings_path, notice: "Оценка удалена" }
    end
  end

  # POST /skill_ratings/1/approve
  def approve
    @skill_rating = SkillRating.includes(:user, :technology, :quarter).find(params[:id])
    authorize @skill_rating, :approve?

    if @skill_rating.approve!(current_user)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("flash", partial: "shared/flash", locals: { notice: "Оценка утверждена" }),
            turbo_stream.replace(@skill_rating, partial: "skill_ratings/rating_card", locals: { skill_rating: @skill_rating })
          ]
        end
        format.html { redirect_to @skill_rating, notice: "Оценка утверждена" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream.update("flash", partial: "shared/flash", locals: { alert: "Ошибка при утверждении оценки" }) }
        format.html { redirect_to @skill_rating, alert: "Ошибка при утверждении оценки" }
      end
    end
  end

  # POST /skill_ratings/1/reject
  def reject
    @skill_rating = SkillRating.includes(:user, :technology, :quarter).find(params[:id])
    authorize @skill_rating, :reject?

    if @skill_rating.reject!(current_user, params[:reason])
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.update("flash", partial: "shared/flash", locals: { notice: "Оценка отклонена" }),
            turbo_stream.replace(@skill_rating, partial: "skill_ratings/rating_card", locals: { skill_rating: @skill_rating })
          ]
        end
        format.html { redirect_to @skill_rating, notice: "Оценка отклонена" }
      end
    else
      respond_to do |format|
        format.turbo_stream { render turbo_stream.update("flash", partial: "shared/flash", locals: { alert: "Ошибка при отклонении оценки" }) }
        format.html { redirect_to @skill_rating, alert: "Ошибка при отклонении оценки" }
      end
    end
  end

  # GET /skill_ratings/user/1
  def user_ratings
    @user = User.find(params[:user_id])
    authorize SkillRating.new(user: @user), :show?

    @skill_ratings = policy_scope(SkillRating)
                    .includes(:technology, :quarter)
                    .where(user: @user)
                    .order('technologies.name ASC')
                    .page(params[:page])

    respond_to do |format|
      format.html { render :user_ratings }
      format.turbo_stream { render turbo_stream.update("skill_ratings_list", partial: "skill_ratings/list") }
    end
  end

  # GET /skill_ratings/team/1
  def team_ratings
    @team = Team.find(params[:team_id])
    @skill_ratings = policy_scope(SkillRating)
                    .includes(:user, :technology, :quarter)
                    .joins(:user).where(users: { team: @team })
                    .order('users.first_name ASC, technologies.name ASC')
                    .page(params[:page])

    respond_to do |format|
      format.html { render :team_ratings }
      format.turbo_stream { render turbo_stream.update("skill_ratings_list", partial: "skill_ratings/list") }
    end
  end

  # GET /skill_ratings/technology/1
  def technology_ratings
    @technology = Technology.find(params[:technology_id])
    @skill_ratings = policy_scope(SkillRating)
                    .includes(:user, :quarter)
                    .where(technology: @technology)
                    .order('users.first_name ASC, quarters.name ASC')
                    .page(params[:page])

    respond_to do |format|
      format.html { render :technology_ratings }
      format.turbo_stream { render turbo_stream.update("skill_ratings_list", partial: "skill_ratings/list") }
    end
  end

  # GET /skill_ratings/pending_approvals
  def pending_approvals
    @skill_ratings = policy_scope(SkillRating)
                    .includes(:user, :technology, :quarter)
                    .where(status: %w[draft submitted])
                    .order('technologies.name ASC, users.first_name ASC')
                    .page(params[:page])

    respond_to do |format|
      format.html { render :pending_approvals }
      format.turbo_stream { render turbo_stream.update("skill_ratings_list", partial: "skill_ratings/list") }
    end
  end

  # POST /skill_ratings/copy_from_previous
  def copy_from_previous
    from_quarter = @quarter.previous_quarter
    if from_quarter.blank?
      redirect_to skill_ratings_path, alert: "Нет предыдущего квартала для копирования"
      return
    end

    authorize SkillRating.new, :copy_from_previous?

    copied_count = SkillRating.copy_ratings_to_new_quarter(from_quarter, @quarter, current_user)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update("flash", partial: "shared/flash", locals: {
            notice: "Успешно скопировано #{copied_count} оценок из #{from_quarter.full_name}"
          }),
          turbo_stream.update("skill_ratings_list", partial: "skill_ratings/list")
        ]
      end
      format.html { redirect_to skill_ratings_path, notice: "Успешно скопировано #{copied_count} оценок из #{from_quarter.full_name}" }
    end
  end

  private

  def set_skill_rating
    @skill_rating = SkillRating.find(params[:id])
  end

  def set_quarter
    @quarter = Quarter.find(params[:quarter_id]) if params[:quarter_id].present?
    @quarter ||= Quarter.current
  end

  def require_active_quarter
    return if @quarter&.active? || @quarter&.draft?
    redirect_to skill_ratings_path, alert: "Оценки можно создавать и редактировать только в активных или черновых кварталах"
  end

  def authorize_skill_rating
    authorize @skill_rating
  end

  def set_available_data
    @technologies = Technology.active.ordered
    @quarters = Quarter.ordered
    @users = policy_scope(User).active.order(:first_name, :last_name)
  end

  def skill_rating_params
    params.require(:skill_rating).permit(
      :user_id, :technology_id, :quarter_id, :rating, :comment, :reason
    )
  end
end
