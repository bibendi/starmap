require "rails_helper"

RSpec.describe "Admin::Quarters", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:quarter) { create(:quarter) }
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
        expect(response.body).to include(quarter.name)
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

    context "when user is authenticated as unit_lead" do
      before { sign_in unit_lead, scope: :user }

      it "returns successful response" do
        get admin_quarters_path
        expect(response).to be_successful
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
end
