require "rails_helper"

RSpec.describe "Admin::Teams", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:unit) { create(:unit, name: "Engineering") }
  let_it_be(:other_unit) { create(:unit, name: "Marketing") }
  let_it_be(:unit_lead) { create(:unit_lead, team: nil) }
  let_it_be(:team) { create(:team, name: "Alpha Team", unit: unit) }
  let_it_be(:team_lead_user) { create(:team_lead, team: team) }
  let_it_be(:inactive_team) { create(:team, name: "Legacy Team", unit: unit, active: false) }

  before do
    team.update!(team_lead: team_lead_user)
  end

  describe "GET /admin/teams" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_teams_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_teams_path
        expect(response).to be_successful
      end

      it "displays teams list" do
        get admin_teams_path
        expect(response.body).to include("Alpha Team")
      end

      it "filters by active status" do
        get admin_teams_path, params: {active: "true"}
        expect(response.body).to include("Alpha Team")
        expect(response.body).not_to include("Legacy Team")
      end

      it "filters by inactive status" do
        get admin_teams_path, params: {active: "false"}
        expect(response.body).to include("Legacy Team")
      end

      it "filters by name" do
        get admin_teams_path, params: {name: "Alpha"}
        expect(response.body).to include("Alpha Team")
        expect(response.body).not_to include("Legacy Team")
      end

      it "filters by unit" do
        create(:team, name: "Marketing Team", unit: other_unit)

        get admin_teams_path, params: {unit_id: other_unit.id}
        expect(response.body).to include("Marketing Team")
        expect(response.body).not_to include("Alpha Team")
      end

      it "orders by name" do
        create(:team, name: "Bravo Team", unit: unit)
        create(:team, name: "Aardvark Team", unit: unit)

        get admin_teams_path
        expect(response.body.index("Aardvark Team")).to be < response.body.index("Bravo Team")
      end

      it "paginates results" do
        stub_const("Admin::TeamsController::PER_PAGE", 1)
        get admin_teams_path
        expect(response.body).to match(/page|pagination/i)
      end
    end

    context "when user is authenticated as unit lead" do
      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "returns successful response" do
        get admin_teams_path
        expect(response).to be_successful
      end

      it "displays only teams from their unit" do
        create(:team, name: "Marketing Team", unit: other_unit)

        get admin_teams_path
        expect(response.body).to include("Alpha Team")
        expect(response.body).not_to include("Marketing Team")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get admin_teams_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/teams/:id" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_team_path(team)
        expect(response).to be_successful
      end

      it "displays team name" do
        get admin_team_path(team)
        expect(response.body).to include("Alpha Team")
      end

      it "displays team lead" do
        get admin_team_path(team)
        expect(response.body).to include(team_lead_user.display_name_or_full_name)
      end

      it "displays unit name" do
        get admin_team_path(team)
        expect(response.body).to include("Engineering")
      end

      it "returns 404 for non-existent team" do
        get admin_team_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as unit lead" do
      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "shows team in their unit" do
        get admin_team_path(team)
        expect(response).to be_successful
        expect(response.body).to include("Alpha Team")
      end

      it "returns not found for team in another unit" do
        other_team = create(:team, name: "Other Team", unit: other_unit)

        expect {
          get admin_team_path(other_team)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get admin_team_path(team)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/teams/new" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get new_admin_team_path
        expect(response).to be_successful
      end

      it "displays form fields" do
        get new_admin_team_path
        expect(response.body).to include("name")
        expect(response.body).to include("description")
      end
    end

    context "when user is authenticated as unit lead" do
      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "returns successful response" do
        get new_admin_team_path
        expect(response).to be_successful
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get new_admin_team_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/teams" do
    let(:valid_params) do
      {
        team: {
          name: "New Team",
          description: "A new team",
          unit_id: unit.id,
          active: true
        }
      }
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "creates new team with valid params" do
        expect {
          post admin_teams_path, params: valid_params
        }.to change(Team, :count).by(1)
      end

      it "redirects to show page with notice" do
        post admin_teams_path, params: valid_params
        expect(response).to redirect_to(admin_team_path(Team.last))
        expect(flash[:notice]).to be_present
      end

      it "does not create with duplicate name" do
        expect {
          post admin_teams_path, params: valid_params
        }.to change(Team, :count).by(1)

        expect {
          post admin_teams_path, params: valid_params
        }.not_to change(Team, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create with empty name" do
        expect {
          post admin_teams_path, params: {team: {name: "", unit_id: unit.id}}
        }.not_to change(Team, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "sets team lead when user is a member" do
        member = create(:engineer)
        params = valid_params[:team].merge(team_lead_id: member.id, member_ids: [member.id])
        post admin_teams_path, params: {team: params}
        expect(Team.last.team_lead).to eq(member)
      end
    end

    context "when user is authenticated as unit lead" do
      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "creates team scoped to their unit" do
        expect {
          post admin_teams_path, params: {
            team: {name: "Unit Lead Team", unit_id: unit.id, active: true}
          }
        }.to change(Team, :count).by(1)

        expect(Team.last.unit_id).to eq(unit.id)
      end

      it "redirects to show page with notice" do
        post admin_teams_path, params: {
          team: {name: "Unit Lead Team", unit_id: unit.id, active: true}
        }
        expect(response).to redirect_to(admin_team_path(Team.last))
        expect(flash[:notice]).to be_present
      end

      it "does not create with empty name" do
        expect {
          post admin_teams_path, params: {team: {name: "", unit_id: unit.id}}
        }.not_to change(Team, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          post admin_teams_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/teams/:id/edit" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get edit_admin_team_path(team)
        expect(response).to be_successful
      end

      it "displays form with team data" do
        get edit_admin_team_path(team)
        expect(response.body).to include("Alpha Team")
      end
    end

    context "when user is authenticated as unit lead" do
      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "returns successful response for team in their unit" do
        get edit_admin_team_path(team)
        expect(response).to be_successful
      end

      it "denies access for team in another unit" do
        other_team = create(:team, name: "Other Team", unit: other_unit)

        expect {
          get edit_admin_team_path(other_team)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get edit_admin_team_path(team)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/teams/:id" do
    let(:valid_update_params) do
      {
        team: {
          name: "Updated Name",
          description: "Updated description"
        }
      }
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "updates team with valid params" do
        patch admin_team_path(team), params: valid_update_params
        team.reload
        expect(team.name).to eq("Updated Name")
        expect(team.description).to eq("Updated description")
      end

      it "redirects to show page with notice" do
        patch admin_team_path(team), params: valid_update_params
        expect(response).to redirect_to(admin_team_path(team))
        expect(flash[:notice]).to be_present
      end

      it "renders form with errors when name is empty" do
        patch admin_team_path(team), params: {team: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "adds member and sets as team lead in single request" do
        engineer = create(:engineer)
        patch admin_team_path(team), params: {
          team: {name: team.name, team_lead_id: engineer.id, member_ids: [engineer.id]}
        }
        team.reload
        expect(team.team_lead).to eq(engineer)
        expect(team.users).to include(engineer)
        expect(response).to redirect_to(admin_team_path(team))
      end

      it "rolls back member changes when team attributes are invalid" do
        engineer = create(:engineer)
        expect {
          patch admin_team_path(team), params: {
            team: {name: "", team_lead_id: engineer.id, member_ids: [engineer.id]}
          }
        }.not_to change(engineer, :team_id)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is authenticated as unit lead" do
      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "updates team name" do
        patch admin_team_path(team), params: {team: {name: "Renamed Team"}}
        team.reload
        expect(team.name).to eq("Renamed Team")
      end

      it "redirects to show page with notice" do
        patch admin_team_path(team), params: {team: {name: "Renamed Team"}}
        expect(response).to redirect_to(admin_team_path(team))
        expect(flash[:notice]).to be_present
      end

      it "renders form with errors when name is empty" do
        patch admin_team_path(team), params: {team: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "cannot update team's unit to another unit" do
        original_unit_id = team.unit_id
        patch admin_team_path(team), params: {team: {name: "Same Team", unit_id: other_unit.id}}
        team.reload
        expect(team.unit_id).to eq(original_unit_id)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          patch admin_team_path(team), params: valid_update_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/teams/:id" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "deletes team without users" do
        empty_team = create(:team, name: "Empty Team", unit: unit)

        expect {
          delete admin_team_path(empty_team)
        }.to change(Team, :count).by(-1)
      end

      it "redirects to index with notice" do
        empty_team = create(:team, name: "Empty Team", unit: unit)

        delete admin_team_path(empty_team)
        expect(response).to redirect_to(admin_teams_path)
        expect(flash[:notice]).to be_present
      end

      it "does not delete team with users" do
        team_with_user = create(:team, name: "Populated Team", unit: unit)
        create(:engineer, team: team_with_user)

        expect {
          delete admin_team_path(team_with_user)
        }.not_to change(Team, :count)

        expect(response).to redirect_to(admin_teams_path)
        expect(flash[:alert]).to be_present
      end

      it "returns 404 for non-existent team" do
        delete admin_team_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as unit lead" do
      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "deletes empty team in their unit" do
        empty_team = create(:team, name: "Empty Team", unit: unit)

        expect {
          delete admin_team_path(empty_team)
        }.to change(Team, :count).by(-1)

        expect(response).to redirect_to(admin_teams_path)
        expect(flash[:notice]).to be_present
      end

      it "does not delete team with users" do
        team_with_user = create(:team, name: "Populated Team", unit: unit)
        create(:engineer, team: team_with_user)

        expect {
          delete admin_team_path(team_with_user)
        }.not_to change(Team, :count)

        expect(response).to redirect_to(admin_teams_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        empty_team = create(:team, name: "Empty Team", unit: unit)
        expect {
          delete admin_team_path(empty_team)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
