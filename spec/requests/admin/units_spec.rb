require "rails_helper"

RSpec.describe "Admin::Units", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:unit_lead_user) { create(:user, first_name: "John", last_name: "Doe", role: "admin", team: nil) }
  let_it_be(:unit) { create(:unit, name: "Engineering", unit_lead: unit_lead_user) }
  let_it_be(:inactive_unit) { create(:unit, name: "Legacy Unit", active: false) }

  describe "GET /admin/units" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_units_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_units_path
        expect(response).to be_successful
      end

      it "displays units list" do
        get admin_units_path
        expect(response.body).to include("Engineering")
      end

      it "filters by active status" do
        get admin_units_path, params: {active: "true"}
        expect(response.body).to include("Engineering")
        expect(response.body).not_to include("Legacy Unit")
      end

      it "filters by inactive status" do
        get admin_units_path, params: {active: "false"}
        expect(response.body).to include("Legacy Unit")
      end

      it "filters by name" do
        get admin_units_path, params: {name: "Engineer"}
        expect(response.body).to include("Engineering")
        expect(response.body).not_to include("Legacy Unit")
      end

      it "orders by name" do
        create(:unit, name: "Bravo")
        create(:unit, name: "Alpha")

        get admin_units_path
        expect(response.body.index("Alpha")).to be < response.body.index("Bravo")
      end

      it "paginates results" do
        stub_const("Admin::UnitsController::PER_PAGE", 1)
        get admin_units_path
        expect(response.body).to match(/page|pagination/i)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get admin_units_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/units/:id" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_unit_path(unit)
        expect(response).to be_successful
      end

      it "displays unit name" do
        get admin_unit_path(unit)
        expect(response.body).to include("Engineering")
      end

      it "displays unit lead" do
        get admin_unit_path(unit)
        expect(response.body).to include("John Doe")
      end

      it "returns 404 for non-existent unit" do
        get admin_unit_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get admin_unit_path(unit)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/units/new" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get new_admin_unit_path
        expect(response).to be_successful
      end

      it "displays form fields" do
        get new_admin_unit_path
        expect(response.body).to include("name")
        expect(response.body).to include("description")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get new_admin_unit_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/units" do
    let(:valid_params) do
      {
        unit: {
          name: "New Unit",
          description: "A new unit",
          active: true
        }
      }
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "creates new unit with valid params" do
        expect {
          post admin_units_path, params: valid_params
        }.to change(Unit, :count).by(1)
      end

      it "redirects to show page with notice" do
        post admin_units_path, params: valid_params
        expect(response).to redirect_to(admin_unit_path(Unit.last))
        expect(flash[:notice]).to be_present
      end

      it "does not create with duplicate name" do
        expect {
          post admin_units_path, params: valid_params
        }.to change(Unit, :count).by(1)

        expect {
          post admin_units_path, params: valid_params
        }.not_to change(Unit, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "does not create with empty name" do
        expect {
          post admin_units_path, params: {unit: {name: ""}}
        }.not_to change(Unit, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          post admin_units_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/units/:id/edit" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get edit_admin_unit_path(unit)
        expect(response).to be_successful
      end

      it "displays form with unit data" do
        get edit_admin_unit_path(unit)
        expect(response.body).to include("Engineering")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get edit_admin_unit_path(unit)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/units/:id" do
    let(:valid_update_params) do
      {
        unit: {
          name: "Updated Name",
          description: "Updated description"
        }
      }
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "updates unit with valid params" do
        patch admin_unit_path(unit), params: valid_update_params
        unit.reload
        expect(unit.name).to eq("Updated Name")
        expect(unit.description).to eq("Updated description")
      end

      it "redirects to show page with notice" do
        patch admin_unit_path(unit), params: valid_update_params
        expect(response).to redirect_to(admin_unit_path(unit))
        expect(flash[:notice]).to be_present
      end

      it "renders form with errors when name is empty" do
        patch admin_unit_path(unit), params: {unit: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          patch admin_unit_path(unit), params: valid_update_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/units/:id" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "deletes unit without teams" do
        unit_without_teams = create(:unit, name: "Empty Unit")

        expect {
          delete admin_unit_path(unit_without_teams)
        }.to change(Unit, :count).by(-1)
      end

      it "redirects to index with notice" do
        unit_without_teams = create(:unit, name: "Empty Unit")

        delete admin_unit_path(unit_without_teams)
        expect(response).to redirect_to(admin_units_path)
        expect(flash[:notice]).to be_present
      end

      it "does not delete unit with teams" do
        team = create(:team)
        unit_with_teams = team.unit

        expect {
          delete admin_unit_path(unit_with_teams)
        }.not_to change(Unit, :count)

        expect(response).to redirect_to(admin_units_path)
        expect(flash[:alert]).to be_present
      end

      it "returns 404 for non-existent unit" do
        delete admin_unit_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        unit_without_teams = create(:unit, name: "Empty Unit")
        expect {
          delete admin_unit_path(unit_without_teams)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
