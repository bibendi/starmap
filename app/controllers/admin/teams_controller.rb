module Admin
  class TeamsController < BaseController
    PER_PAGE = 25

    before_action :set_team, only: [:show, :edit, :update, :destroy]

    def index
      authorize [:admin, Team]
      @teams = policy_scope([:admin, Team]).includes(:unit, :team_lead)
      @teams = filter_by_active(@teams)
      @teams = filter_by_name(@teams)
      @teams = filter_by_unit(@teams)
      @teams = @teams.ordered.page(params[:page]).per(PER_PAGE)
    end

    def show
      authorize [:admin, @team]
    end

    def new
      authorize [:admin, Team]
      @team = Team.new
      @team.unit = current_user.unit if current_user.unit_lead?
      set_available_members
    end

    def create
      authorize [:admin, Team]
      attrs = permitted_attributes([:admin, Team])
      member_ids = attrs.delete(:member_ids)
      @team = Team.new(attrs)
      @team.unit = current_user.unit if current_user.unit_lead?
      @team.save!
      @team.sync_members!(member_ids) if member_ids
      redirect_to admin_team_path(@team), notice: t("admin.teams.created")
    rescue ActiveRecord::RecordInvalid
      set_available_members
      render :new, status: :unprocessable_content
    end

    def edit
      authorize [:admin, @team]
      set_available_members
    end

    def update
      authorize [:admin, @team]
      attrs = permitted_attributes([:admin, @team])
      member_ids = attrs.delete(:member_ids)

      Team.transaction do
        @team.sync_members!(member_ids.compact_blank) if member_ids
        @team.update!(attrs)
      end

      redirect_to admin_team_path(@team), notice: t("admin.teams.updated")
    rescue ActiveRecord::RecordInvalid
      set_available_members
      render :edit, status: :unprocessable_content
    end

    def destroy
      authorize [:admin, @team]

      if @team.destroy
        redirect_to admin_teams_path, notice: t("admin.teams.destroyed")
      else
        redirect_to admin_teams_path, alert: t("admin.teams.cannot_delete_with_users")
      end
    end

    private

    def set_team
      @team = Team.find(params[:id])
    end

    def filter_by_active(scope)
      return scope if params[:active].blank?
      scope.where(active: params[:active])
    end

    def filter_by_name(scope)
      return scope if params[:name].blank?
      scope.where("name ILIKE ?", "%#{params[:name]}%")
    end

    def filter_by_unit(scope)
      return scope if params[:unit_id].blank?
      scope.where(unit_id: params[:unit_id])
    end

    def set_available_members
      @available_members = User.unassigned_engineers.order(:first_name, :last_name)
    end
  end
end
