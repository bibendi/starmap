require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team) { create(:team) }
  let_it_be(:active_user) { create(:user, first_name: "Active", last_name: "User", active: true, team: team, position: "Developer") }
  let_it_be(:inactive_user) { create(:user, first_name: "Inactive", last_name: "User", active: false, team: team) }

  describe "GET /admin/users" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_users_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_users_path
        expect(response).to be_successful
      end

      it "displays users list" do
        get admin_users_path
        expect(response.body).to include(active_user.full_name)
      end

      it "displays inactive users when filtering" do
        get admin_users_path, params: {status: "inactive"}
        expect(response.body).to include(inactive_user.full_name)
      end

      it "hides inactive users by default" do
        get admin_users_path
        expect(response.body).not_to include(inactive_user.full_name)
      end

      it "filters users by role" do
        get admin_users_path, params: {role: "engineer"}
        expect(response.body).to include(engineer.full_name)
      end

      it "filters users by team" do
        get admin_users_path, params: {team_id: team.id}
        expect(response.body).to include(active_user.full_name)
      end

      it "searches users by name" do
        get admin_users_path, params: {search: "Active"}
        expect(response.body).to include(active_user.full_name)
        expect(response.body).not_to include(inactive_user.full_name)
      end

      it "searches users by email" do
        get admin_users_path, params: {search: active_user.email}
        expect(response.body).to include(active_user.full_name)
      end

      it "sorts users by name" do
        get admin_users_path, params: {sort: "name", direction: "asc"}
        expect(response.body).to include(active_user.full_name)
      end

      it "sorts users by email" do
        get admin_users_path, params: {sort: "email", direction: "asc"}
        expect(response.body).to include(active_user.full_name)
      end

      it "sorts users by created_at" do
        get admin_users_path, params: {sort: "created_at", direction: "desc"}
        expect(response.body).to include(active_user.full_name)
      end

      it "has sortable column headers" do
        get admin_users_path
        expect(response.body).to include("sort=name")
        expect(response.body).to include("sort=email")
        expect(response.body).to include("sort=role")
      end

      it "displays pagination when there are more users than per page" do
        stub_const("Admin::UsersController::PER_PAGE", 1)
        get admin_users_path
        expect(response.body).to match(/page|pagination/i)
      end

      it "displays role filter options" do
        get admin_users_path
        expect(response.body).to include("role")
      end

      it "displays status filter options" do
        get admin_users_path
        expect(response.body).to include("status")
      end

      it "displays new user button" do
        get admin_users_path
        expect(response.body).to include("btn--primary")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        expect {
          get admin_users_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is authenticated as team_lead" do
      before { sign_in team_lead, scope: :user }

      it "denies access with 403" do
        expect {
          get admin_users_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is authenticated as unit_lead" do
      before { sign_in unit_lead, scope: :user }

      it "denies access with 403" do
        expect {
          get admin_users_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/users/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_user_path(active_user)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_user_path(active_user)
        expect(response).to be_successful
      end

      it "displays user name" do
        get admin_user_path(active_user)
        expect(response.body).to include(active_user.full_name)
      end

      it "displays user email" do
        get admin_user_path(active_user)
        expect(response.body).to include(active_user.email)
      end

      it "displays user position" do
        get admin_user_path(active_user)
        expect(response.body).to include(active_user.position)
      end

      it "displays user role" do
        get admin_user_path(active_user)
        expect(response.body).to include(active_user.role.humanize)
      end

      it "displays user team" do
        get admin_user_path(active_user)
        expect(response.body).to include(active_user.team.name)
      end

      it "displays user status" do
        get admin_user_path(active_user)
        expect(response.body).to include("Active")
      end

      it "displays created_at" do
        get admin_user_path(active_user)
        expect(response.body).to include(I18n.l(active_user.created_at, format: :short))
      end

      it "displays edit button" do
        get admin_user_path(active_user)
        expect(response.body).to include("btn--primary")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        expect {
          get admin_user_path(active_user)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is authenticated as team_lead" do
      before { sign_in team_lead, scope: :user }

      it "denies access with 403" do
        expect {
          get admin_user_path(active_user)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is authenticated as unit_lead" do
      before { sign_in unit_lead, scope: :user }

      it "denies access with 403" do
        expect {
          get admin_user_path(active_user)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/users/new" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get new_admin_user_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get new_admin_user_path
        expect(response).to be_successful
      end

      it "displays form fields" do
        get new_admin_user_path
        expect(response.body).to include("first_name")
        expect(response.body).to include("last_name")
        expect(response.body).to include("email")
        expect(response.body).to include("password")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        expect {
          get new_admin_user_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/users" do
    let(:valid_params) do
      {
        user: {
          first_name: "New",
          last_name: "User",
          email: "newuser@example.com",
          password: "Password123!",
          password_confirmation: "Password123!",
          role: "engineer",
          team_id: team.id,
          active: true
        }
      }
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        post admin_users_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "creates new user with valid params" do
        expect {
          post admin_users_path, params: valid_params
        }.to change(User, :count).by(1)
      end

      it "redirects to users list with notice" do
        post admin_users_path, params: valid_params
        expect(response).to redirect_to(admin_users_path)
        expect(flash[:notice]).to be_present
      end

      it "does not create user with duplicate email" do
        create(:user, email: valid_params[:user][:email])
        expect {
          post admin_users_path, params: valid_params
        }.not_to change(User, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "requires password" do
        invalid_params = {user: valid_params[:user].merge(password: "", password_confirmation: "")}
        post admin_users_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          post admin_users_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/users/:id/edit" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get edit_admin_user_path(active_user)
        expect(response).to be_successful
      end

      it "displays form fields with user data" do
        get edit_admin_user_path(active_user)
        expect(response.body).to include(active_user.first_name)
        expect(response.body).to include(active_user.last_name)
        expect(response.body).to include(active_user.email)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        expect {
          get edit_admin_user_path(active_user)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/users/:id" do
    let(:valid_update_params) do
      {
        user: {
          first_name: "Updated",
          last_name: "Name",
          position: "Senior Developer"
        }
      }
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "updates user with valid params" do
        patch admin_user_path(active_user), params: valid_update_params
        active_user.reload
        expect(active_user.first_name).to eq("Updated")
        expect(active_user.last_name).to eq("Name")
        expect(active_user.position).to eq("Senior Developer")
      end

      it "redirects to user page with notice" do
        patch admin_user_path(active_user), params: valid_update_params
        expect(response).to redirect_to(admin_user_path(active_user))
        expect(flash[:notice]).to be_present
      end

      it "renders form with errors when invalid" do
        patch admin_user_path(active_user), params: {user: {email: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          patch admin_user_path(active_user), params: valid_update_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "team_lead uniqueness per team" do
    let(:team) { create(:team) }

    context "when creating a new team_lead" do
      before { sign_in admin, scope: :user }

      it "prevents creating second team_lead for same team" do
        create(:team_lead, team: team)
        new_lead_params = {
          user: {
            first_name: "New",
            last_name: "Lead",
            email: "newlead@example.com",
            password: "Password123!",
            password_confirmation: "Password123!",
            role: "team_lead",
            team_id: team.id,
            active: true
          }
        }
        post admin_users_path, params: new_lead_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("activerecord.errors.messages.team_already_has_lead"))
      end
    end

    context "when updating user to team_lead" do
      before { sign_in admin, scope: :user }

      it "prevents when team already has team_lead" do
        existing_lead = create(:team_lead, team: team)
        engineer = create(:engineer, team: team)

        patch admin_user_path(engineer), params: {user: {role: "team_lead"}}

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include(I18n.t("activerecord.errors.messages.team_already_has_lead"))
        expect(existing_lead.reload.team_lead?).to be true
      end
    end

    context "when changing team_lead to different team" do
      before { sign_in admin, scope: :user }

      it "allows reassigning team_lead to empty team" do
        lead = create(:team_lead, team: team)
        other_team = create(:team)

        patch admin_user_path(lead), params: {user: {team_id: other_team.id}}

        lead.reload
        expect(lead.team_id).to eq(other_team.id)
        expect(response).not_to have_http_status(:unprocessable_content)
      end
    end
  end
end
