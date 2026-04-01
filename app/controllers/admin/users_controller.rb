module Admin
  class UsersController < BaseController
    PER_PAGE = 25

    def index
      authorize [:admin, User]
      @users = policy_scope([:admin, User]).includes(:team)
      @users = filter_by_role(@users)
      @users = filter_by_status(@users)
      @users = filter_by_team(@users)
      @users = search(@users)
      @users = sort(@users)
      @users = @users.page(params[:page]).per(PER_PAGE)
    end

    def new
      authorize [:admin, User]
      @user = User.new
    end

    def create
      authorize [:admin, User]
      @user = User.new(user_params)
      @user.confirmed_at = Time.current

      if @user.save
        redirect_to admin_users_path, notice: t("admin.users.created")
      else
        render :new, status: :unprocessable_content
      end
    end

    def show
      @user = User.find(params[:id])
      authorize [:admin, @user]
    end

    def edit
      @user = User.find(params[:id])
      authorize [:admin, @user]
    end

    def update
      @user = User.find(params[:id])
      authorize [:admin, @user]

      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: t("admin.users.updated")
      else
        render :edit, status: :unprocessable_content
      end
    end

    private

    def user_params
      params.require(:user).permit(
        :email,
        :first_name,
        :last_name,
        :position,
        :role,
        :active,
        :password,
        :password_confirmation
      )
    end

    def filter_by_role(scope)
      return scope if params[:role].blank?
      scope.where(role: params[:role])
    end

    def filter_by_status(scope)
      return scope.active if params[:status].blank? || params[:status] == "active"
      return scope.where(active: false) if params[:status] == "inactive"
      scope
    end

    def filter_by_team(scope)
      return scope if params[:team_id].blank?
      scope.where(team_id: params[:team_id])
    end

    def search(scope)
      return scope if params[:search].blank?
      term = "%#{params[:search]}%"
      scope.where("first_name ILIKE ? OR last_name ILIKE ? OR email ILIKE ?", term, term, term)
    end

    def sort(scope)
      sort_param = params[:sort] || "name"
      direction = (params[:direction] == "desc") ? :desc : :asc

      case sort_param
      when "name"
        scope.order(first_name: direction, last_name: direction)
      when "email"
        scope.order(email: direction)
      when "role"
        scope.order(role: direction)
      when "created_at"
        scope.order(created_at: direction)
      else
        scope.order(first_name: :asc, last_name: :asc)
      end
    end
  end
end
