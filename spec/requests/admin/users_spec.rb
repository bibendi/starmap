require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:team_lead) { create(:team_lead) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:team) { create(:team) }
  let_it_be(:active_user) { create(:user, first_name: "Active", last_name: "User", active: true, team: team) }
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
end
