require "rails_helper"

RSpec.describe "Admin::Quarters", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:draft_quarter) { create(:quarter, status: :draft) }
  let_it_be(:active_quarter) { create(:quarter, status: :active, is_current: true) }
  let_it_be(:closed_quarter) { create(:quarter, status: :closed) }

  describe "GET /admin/quarters" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_quarters_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_quarters_path
        expect(response).to be_successful
      end

      it "displays quarters list" do
        get admin_quarters_path
        expect(response.body).to include(draft_quarter.name)
      end

      it "displays status filter options" do
        get admin_quarters_path
        expect(response.body).to include("status")
      end

      it "filters quarters by status" do
        get admin_quarters_path, params: {status: "draft"}
        expect(response.body).to include(draft_quarter.name)
        expect(response.body).not_to include(closed_quarter.name)
      end

      it "displays pagination when there are more quarters than per page" do
        stub_const("Admin::QuartersController::PER_PAGE", 2)
        get admin_quarters_path
        expect(response.body).to match(/page|pagination/i)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        expect {
          get admin_quarters_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/quarters/:id/activate" do
    context "when user is admin" do
      before do
        sign_in admin, scope: :user
        # Close existing active quarter to allow activation
        QuarterStatusService.new(active_quarter, admin).close if active_quarter.active?
      end

      it "transitions draft quarter to active" do
        fresh_draft = create(:quarter, status: :draft)
        post activate_admin_quarter_path(fresh_draft)
        expect(fresh_draft.reload.status).to eq "active"
      end

      it "redirects to index with notice" do
        fresh_draft = create(:quarter, status: :draft)
        post activate_admin_quarter_path(fresh_draft)
        expect(response).to redirect_to(admin_quarters_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          post activate_admin_quarter_path(draft_quarter)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/quarters/:id/close" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "transitions active quarter to closed" do
        post close_admin_quarter_path(active_quarter)
        expect(active_quarter.reload.status).to eq "closed"
      end

      it "redirects to index with notice" do
        post close_admin_quarter_path(active_quarter)
        expect(response).to redirect_to(admin_quarters_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          post close_admin_quarter_path(active_quarter)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/quarters/:id/archive" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "transitions closed quarter to archived" do
        post archive_admin_quarter_path(closed_quarter)
        expect(closed_quarter.reload.status).to eq "archived"
      end

      it "redirects to index with notice" do
        post archive_admin_quarter_path(closed_quarter)
        expect(response).to redirect_to(admin_quarters_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          post archive_admin_quarter_path(closed_quarter)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/quarters/new" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get new_admin_quarter_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get new_admin_quarter_path
        expect(response).to be_successful
      end

      it "displays form fields" do
        get new_admin_quarter_path
        expect(response.body).to include("year")
        expect(response.body).to include("quarter_number")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get new_admin_quarter_path
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/quarters" do
    let(:valid_params) do
      {
        quarter: {
          year: Date.current.year + 1,
          quarter_number: 1,
          start_date: "#{Date.current.year + 1}-01-01",
          end_date: "#{Date.current.year + 1}-03-31"
        }
      }
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        post admin_quarters_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "creates new quarter with valid params" do
        expect {
          post admin_quarters_path, params: valid_params
        }.to change(Quarter, :count).by(1)
      end

      it "auto-generates quarter name" do
        post admin_quarters_path, params: valid_params
        quarter = Quarter.last
        expect(quarter.name).to eq("#{valid_params[:quarter][:year]} Q#{valid_params[:quarter][:quarter_number]}")
      end

      it "sets status to draft by default" do
        post admin_quarters_path, params: valid_params
        expect(Quarter.last).to be_draft
      end

      it "redirects to index with notice" do
        post admin_quarters_path, params: valid_params
        expect(response).to redirect_to(admin_quarters_path)
        expect(flash[:notice]).to be_present
      end

      it "auto-calculates evaluation dates" do
        post admin_quarters_path, params: valid_params
        quarter = Quarter.last
        expect(quarter.evaluation_start_date).to be_present
        expect(quarter.evaluation_end_date).to be_present
      end

      it "does not create quarter with duplicate year and quarter_number" do
        create(:quarter, year: valid_params[:quarter][:year], quarter_number: valid_params[:quarter][:quarter_number])
        expect {
          post admin_quarters_path, params: valid_params
        }.not_to change(Quarter, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "renders form with errors when quarter_number is invalid" do
        invalid_params = {quarter: {year: valid_params[:quarter][:year], quarter_number: 5}}
        post admin_quarters_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("quarter_number")
      end

      it "requires year to be current or future" do
        invalid_params = {
          quarter: {
            year: 2020,
            quarter_number: 1,
            start_date: "2020-01-01",
            end_date: "2020-03-31"
          }
        }
        post admin_quarters_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          post admin_quarters_path, params: valid_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/quarters/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_quarter_path(draft_quarter)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_quarter_path(draft_quarter)
        expect(response).to be_successful
      end

      it "displays quarter details" do
        get admin_quarter_path(draft_quarter)
        expect(response.body).to include(draft_quarter.name)
        expect(response.body).to include(draft_quarter.status)
        expect(response.body).to include(draft_quarter.start_date.to_s)
      end

      it "displays related metrics" do
        get admin_quarter_path(active_quarter)
        expect(response.body).to match(/skill_ratings|оценки|ratings/i)
      end

      it "displays status management buttons for draft quarter" do
        get admin_quarter_path(draft_quarter)
        expect(response.body).to match(/activate|активировать/i)
      end

      it "displays status management buttons for active quarter" do
        get admin_quarter_path(active_quarter)
        expect(response.body).to match(/close|закрыть/i)
      end

      it "displays status management buttons for closed quarter" do
        get admin_quarter_path(closed_quarter)
        expect(response.body).to match(/archive|архивировать/i)
      end

      it "returns 404 for non-existent quarter" do
        non_existent_id = (Quarter.maximum(:id) || 0) + 999999
        get admin_quarter_path(non_existent_id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get admin_quarter_path(draft_quarter)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/quarters/:id/edit" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get edit_admin_quarter_path(draft_quarter)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response for draft quarter" do
        get edit_admin_quarter_path(draft_quarter)
        expect(response).to be_successful
      end

      it "displays edit form for draft quarter" do
        get edit_admin_quarter_path(draft_quarter)
        expect(response.body).to include("year")
        expect(response.body).to include(draft_quarter.year.to_s)
      end

      it "blocks editing of active quarter" do
        get edit_admin_quarter_path(active_quarter)
        expect(response).to redirect_to(admin_quarter_path(active_quarter))
        expect(flash[:alert]).to be_present
      end

      it "blocks editing of closed quarter" do
        get edit_admin_quarter_path(closed_quarter)
        expect(response).to redirect_to(admin_quarter_path(closed_quarter))
        expect(flash[:alert]).to be_present
      end

      it "blocks editing of closed quarter" do
        expect {
          get edit_admin_quarter_path(closed_quarter)
        }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "returns 404 for non-existent quarter" do
        non_existent_id = (Quarter.maximum(:id) || 0) + 999999
        get edit_admin_quarter_path(non_existent_id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get edit_admin_quarter_path(draft_quarter)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PUT /admin/quarters/:id" do
    let(:valid_update_params) do
      {
        quarter: {
          description: "Updated description",
          start_date: draft_quarter.start_date,
          end_date: draft_quarter.end_date,
          evaluation_start_date: draft_quarter.evaluation_start_date,
          evaluation_end_date: draft_quarter.evaluation_end_date
        }
      }
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        put admin_quarter_path(draft_quarter), params: valid_update_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "updates draft quarter with valid params" do
        put admin_quarter_path(draft_quarter), params: valid_update_params
        expect(draft_quarter.reload.description).to eq("Updated description")
      end

      it "redirects to show page with notice" do
        put admin_quarter_path(draft_quarter), params: valid_update_params
        expect(response).to redirect_to(admin_quarter_path(draft_quarter))
        expect(flash[:notice]).to be_present
      end

      it "renders form with errors when invalid" do
        invalid_params = {quarter: {end_date: draft_quarter.start_date - 1.day}}
        put admin_quarter_path(draft_quarter), params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("error")
      end

      it "denies update for active quarter with authorization error" do
        expect {
          put admin_quarter_path(active_quarter), params: valid_update_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "does not change active quarter data" do
        original_description = active_quarter.description
        begin
          put admin_quarter_path(active_quarter), params: valid_update_params
        rescue Pundit::NotAuthorizedError
          # expected
        end
        expect(active_quarter.reload.description).to eq(original_description)
      end

      it "denies update for closed quarter with authorization error" do
        expect {
          put admin_quarter_path(closed_quarter), params: valid_update_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "does not change closed quarter data" do
        original_description = closed_quarter.description
        begin
          put admin_quarter_path(closed_quarter), params: valid_update_params
        rescue Pundit::NotAuthorizedError
          # expected
        end
        expect(closed_quarter.reload.description).to eq(original_description)
      end

      it "denies update for archived quarter with authorization error" do
        archived_quarter = create(:quarter, status: :archived)
        expect {
          put admin_quarter_path(archived_quarter), params: valid_update_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end

      it "returns 404 for non-existent quarter" do
        non_existent_id = (Quarter.maximum(:id) || 0) + 999999
        put admin_quarter_path(non_existent_id), params: valid_update_params
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          put admin_quarter_path(draft_quarter), params: valid_update_params
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/quarters/:id" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "deletes draft quarter" do
        expect {
          delete admin_quarter_path(draft_quarter)
        }.to change(Quarter, :count).by(-1)
      end

      it "redirects to index with notice" do
        delete admin_quarter_path(draft_quarter)
        expect(response).to redirect_to(admin_quarters_path)
        expect(flash[:notice]).to be_present
      end

      it "does not delete active quarter" do
        expect {
          delete admin_quarter_path(active_quarter)
        }.not_to change(Quarter, :count)
        expect(response).to redirect_to(admin_quarters_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          delete admin_quarter_path(draft_quarter)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
