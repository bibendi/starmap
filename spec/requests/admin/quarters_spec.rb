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
