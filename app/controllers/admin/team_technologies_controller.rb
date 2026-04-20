module Admin
  class TeamTechnologiesController < BaseController
    before_action :set_team
    before_action :authorize_team, only: [:new, :create]

    def new
      @team_technology = @team.team_technologies.build
      @available_technologies = Technology.active
        .where.not(id: @team.technology_ids)
        .order(:name)
    end

    def create
      attrs = permitted_attributes([:admin, TeamTechnology])
      @team_technology = @team.team_technologies.build(attrs)

      if @team_technology.save
        redirect_to admin_team_path(@team), notice: t("admin.team_technologies.created")
      else
        @available_technologies = Technology.active
          .where.not(id: @team.technology_ids)
          .order(:name)
        render :new, status: :unprocessable_content
      end
    end

    def edit
      @team_technology = @team.team_technologies.find(params[:id])
      authorize [:admin, @team_technology]
    end

    def update
      @team_technology = @team.team_technologies.find(params[:id])
      authorize [:admin, @team_technology]

      if @team_technology.update(permitted_attributes([:admin, @team_technology]))
        redirect_to admin_team_path(@team), notice: t("admin.team_technologies.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    def destroy
      @team_technology = @team.team_technologies.find(params[:id])
      authorize [:admin, @team_technology]

      @team_technology.archived!
      redirect_to admin_team_path(@team), notice: t("admin.team_technologies.archived")
    end

    def restore
      @team_technology = @team.team_technologies.find(params[:id])
      authorize [:admin, @team_technology]

      @team_technology.active!
      redirect_to admin_team_path(@team), notice: t("admin.team_technologies.restored")
    end

    private

    def set_team
      @team = Team.find(params[:team_id])
    end

    def authorize_team
      authorize [:admin, @team], :show?
    end
  end
end
