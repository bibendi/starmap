require "rails_helper"

RSpec.describe "Admin::Technologies", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:backend_category) { create(:category, name: "Backend") }
  let_it_be(:frontend_category) { create(:category, name: "Frontend") }
  let_it_be(:technology) { create(:technology, name: "Ruby on Rails", category: backend_category, criticality: "high") }
  let_it_be(:inactive_technology) { create(:technology, :inactive, name: "Legacy Tech", category: frontend_category) }

  describe "GET /admin/technologies" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_technologies_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_technologies_path
        expect(response).to be_successful
      end

      it "displays technologies list" do
        get admin_technologies_path
        expect(response.body).to include("Ruby on Rails")
      end

      it "displays active technologies by default" do
        get admin_technologies_path
        expect(response.body).to include("Ruby on Rails")
      end

      it "filters by active status" do
        get admin_technologies_path, params: {active: "true"}
        expect(response.body).to include("Ruby on Rails")
        expect(response.body).not_to include("Legacy Tech")
      end

      it "filters by inactive status" do
        get admin_technologies_path, params: {active: "false"}
        expect(response.body).to include("Legacy Tech")
      end

      it "filters by name" do
        get admin_technologies_path, params: {name: "Ruby"}
        expect(response.body).to include("Ruby on Rails")
        expect(response.body).not_to include("Legacy Tech")
      end

      it "filters by category" do
        get admin_technologies_path, params: {category_id: backend_category.id}
        expect(response.body).to include("Ruby on Rails")
      end

      it "combines multiple filters" do
        get admin_technologies_path, params: {active: "true", category_id: backend_category.id, name: "Ruby"}
        expect(response.body).to include("Ruby on Rails")
      end

      it "paginates results" do
        stub_const("Admin::TechnologiesController::PER_PAGE", 1)
        get admin_technologies_path
        expect(response.body).to match(/page|pagination/i)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        expect {
          get admin_technologies_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/technologies/:id" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_technology_path(technology)
        expect(response).to be_successful
      end

      it "displays technology name" do
        get admin_technology_path(technology)
        expect(response.body).to include("Ruby on Rails")
      end

      it "displays technology category" do
        get admin_technology_path(technology)
        expect(response.body).to include("Backend")
      end

      it "returns 404 for non-existent technology" do
        get admin_technology_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        expect {
          get admin_technology_path(technology)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/technologies/new" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get new_admin_technology_path
        expect(response).to be_successful
      end

      it "displays form fields" do
        get new_admin_technology_path
        expect(response.body).to include("name")
        expect(response.body).to include("description")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        expect {
          get new_admin_technology_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/technologies" do
    let(:valid_params) do
      {
        technology: {
          name: "New Technology",
          description: "A new technology",
          category_id: backend_category.id,
          criticality: "normal",
          target_experts: 2,
          sort_order: 1,
          active: true
        }
      }
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "creates new technology with valid params" do
        expect {
          post admin_technologies_path, params: valid_params
        }.to change(Technology, :count).by(1)
      end

      it "sets created_by" do
        post admin_technologies_path, params: valid_params
        expect(Technology.last.created_by).to eq(admin)
      end

      it "redirects to show page with notice" do
        post admin_technologies_path, params: valid_params
        expect(response).to redirect_to(admin_technology_path(Technology.last))
        expect(flash[:notice]).to be_present
      end

      it "does not create with duplicate name" do
        create(:technology, name: "New Technology")
        expect {
          post admin_technologies_path, params: valid_params
        }.not_to change(Technology, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          post admin_technologies_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/technologies/:id/edit" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get edit_admin_technology_path(technology)
        expect(response).to be_successful
      end

      it "displays form with technology data" do
        get edit_admin_technology_path(technology)
        expect(response.body).to include("Ruby on Rails")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        expect {
          get edit_admin_technology_path(technology)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/technologies/:id" do
    let(:valid_update_params) do
      {
        technology: {
          name: "Updated Name",
          description: "Updated description"
        }
      }
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "updates technology with valid params" do
        patch admin_technology_path(technology), params: valid_update_params
        technology.reload
        expect(technology.name).to eq("Updated Name")
        expect(technology.description).to eq("Updated description")
      end

      it "redirects to show page with notice" do
        patch admin_technology_path(technology), params: valid_update_params
        expect(response).to redirect_to(admin_technology_path(technology))
        expect(flash[:notice]).to be_present
      end

      it "renders form with errors when invalid" do
        patch admin_technology_path(technology), params: {technology: {name: ""}}
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          patch admin_technology_path(technology), params: valid_update_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/technologies/:id" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "deletes technology" do
        tech = create(:technology, name: "To Delete")
        expect {
          delete admin_technology_path(tech)
        }.to change(Technology, :count).by(-1)
      end

      it "redirects to index with notice" do
        tech = create(:technology, name: "To Delete")
        delete admin_technology_path(tech)
        expect(response).to redirect_to(admin_technologies_path)
        expect(flash[:notice]).to be_present
      end

      it "does not delete technology with skill ratings" do
        tech = create(:technology, name: "Linked Tech")
        create(:skill_rating, technology: tech)

        expect {
          delete admin_technology_path(tech)
        }.not_to change(Technology, :count)

        expect(response).to redirect_to(admin_technologies_path)
        expect(flash[:alert]).to be_present
      end

      it "returns 404 for non-existent technology" do
        delete admin_technology_path(999_999)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        tech = create(:technology, name: "To Delete")
        expect {
          delete admin_technology_path(tech)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/technologies/reorder" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get reorder_admin_technologies_path
        expect(response).to be_successful
      end

      it "displays technologies list" do
        get reorder_admin_technologies_path
        expect(response.body).to include("Ruby on Rails")
        expect(response.body).to include("Legacy Tech")
      end

      it "does not paginate" do
        create_list(:technology, 30)
        get reorder_admin_technologies_path
        expect(response.body).not_to include("paginate")
        expect(response.body).not_to include("nav-pagination")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get reorder_admin_technologies_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/technologies/reorder" do
    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "updates sort_order for given ids and redirects" do
        tech1 = create(:technology, name: "A", sort_order: 1)
        tech2 = create(:technology, name: "B", sort_order: 2)
        tech3 = create(:technology, name: "C", sort_order: 3)

        patch reorder_admin_technologies_path, params: {ids: [tech3.id, tech1.id, tech2.id]}
        expect(response).to redirect_to(admin_technologies_path)

        tech3.reload
        tech1.reload
        tech2.reload
        expect(tech3.sort_order).to eq(0)
        expect(tech1.sort_order).to eq(1)
        expect(tech2.sort_order).to eq(2)
      end

      it "returns unprocessable when ids missing" do
        patch reorder_admin_technologies_path, params: {}
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          patch reorder_admin_technologies_path, params: {ids: [1, 2]}
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
