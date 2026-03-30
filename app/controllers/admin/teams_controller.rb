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
    end

    def create
      authorize [:admin, Team]
      @team = Team.new(team_params)

      if @team.save
        redirect_to admin_team_path(@team), notice: t("admin.teams.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def edit
      authorize [:admin, @team]
    end

    def update
      authorize [:admin, @team]

      if @team.update(team_params)
        redirect_to admin_team_path(@team), notice: t("admin.teams.updated")
      else
        render :edit, status: :unprocessable_content
      end
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

    def team_params
      params.require(:team).permit(:name, :description, :active, :unit_id, :team_lead_id)
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
  end
end
