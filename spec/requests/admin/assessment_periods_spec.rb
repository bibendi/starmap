require "rails_helper"

RSpec.describe "Admin::AssessmentPeriods", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:draft_assessment_period) { create(:assessment_period, status: :draft) }
  let_it_be(:active_assessment_period) { create(:assessment_period, status: :active, is_current: true) }
  let_it_be(:closed_assessment_period) { create(:assessment_period, status: :closed) }

  describe "GET /admin/assessment_periods" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_assessment_periods_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_assessment_periods_path
        expect(response).to be_successful
      end

      it "displays assessment_periods list" do
        get admin_assessment_periods_path
        expect(response.body).to include(draft_assessment_period.name)
      end

      it "displays status filter options" do
        get admin_assessment_periods_path
        expect(response.body).to include("status")
      end

      it "filters assessment_periods by status" do
        get admin_assessment_periods_path, params: {status: "draft"}
        expect(response.body).to include(draft_assessment_period.name)
        expect(response.body).not_to include(closed_assessment_period.name)
      end

      it "displays pagination when there are more assessment_periods than per page" do
        stub_const("Admin::AssessmentPeriodsController::PER_PAGE", 2)
        get admin_assessment_periods_path
        expect(response.body).to match(/page|pagination/i)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access with 403" do
        get admin_assessment_periods_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "POST /admin/assessment_periods/:id/activate" do
    context "when user is admin" do
      before do
        sign_in admin, scope: :user
        # Close existing active assessment_period to allow activation
        AssessmentPeriodStatusService.new(active_assessment_period, admin).close if active_assessment_period.active?
      end

      it "transitions draft assessment_period to active" do
        fresh_draft = create(:assessment_period, status: :draft)
        post activate_admin_assessment_period_path(fresh_draft)
        expect(fresh_draft.reload.status).to eq "active"
      end

      it "redirects to index with notice" do
        fresh_draft = create(:assessment_period, status: :draft)
        post activate_admin_assessment_period_path(fresh_draft)
        expect(response).to redirect_to(admin_assessment_periods_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        post activate_admin_assessment_period_path(draft_assessment_period)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "POST /admin/assessment_periods/:id/close" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "transitions active assessment_period to closed" do
        post close_admin_assessment_period_path(active_assessment_period)
        expect(active_assessment_period.reload.status).to eq "closed"
      end

      it "redirects to index with notice" do
        post close_admin_assessment_period_path(active_assessment_period)
        expect(response).to redirect_to(admin_assessment_periods_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        post close_admin_assessment_period_path(active_assessment_period)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "POST /admin/assessment_periods/:id/archive" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "transitions closed assessment_period to archived" do
        post archive_admin_assessment_period_path(closed_assessment_period)
        expect(closed_assessment_period.reload.status).to eq "archived"
      end

      it "redirects to index with notice" do
        post archive_admin_assessment_period_path(closed_assessment_period)
        expect(response).to redirect_to(admin_assessment_periods_path)
        expect(flash[:notice]).to be_present
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        post archive_admin_assessment_period_path(closed_assessment_period)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "GET /admin/assessment_periods/new" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get new_admin_assessment_period_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get new_admin_assessment_period_path
        expect(response).to be_successful
      end

      it "displays form fields" do
        get new_admin_assessment_period_path
        expect(response.body).to include("year")
        expect(response.body).to include("calendar_number")
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        get new_admin_assessment_period_path
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "POST /admin/assessment_periods" do
    let(:assessment_period_year) { Date.current.year + 50 }
    let(:valid_params) do
      {
        assessment_period: {
          calendar_year: assessment_period_year,
          calendar_number: 1,
          start_date: "#{assessment_period_year}-01-01",
          end_date: "#{assessment_period_year}-03-31",
          evaluation_start_date: "#{assessment_period_year}-04-01",
          evaluation_end_date: "#{assessment_period_year}-04-15"
        }
      }
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        post admin_assessment_periods_path, params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "creates new assessment_period with valid params" do
        expect {
          post admin_assessment_periods_path, params: valid_params
        }.to change(AssessmentPeriod, :count).by(1)
      end

      it "auto-generates assessment_period name" do
        post admin_assessment_periods_path, params: valid_params
        assessment_period = AssessmentPeriod.last
        expect(assessment_period.name).to eq("#{valid_params[:assessment_period][:calendar_year]} Q#{valid_params[:assessment_period][:calendar_number]}")
      end

      it "sets status to draft by default" do
        post admin_assessment_periods_path, params: valid_params
        expect(AssessmentPeriod.last).to be_draft
      end

      it "redirects to index with notice" do
        post admin_assessment_periods_path, params: valid_params
        expect(response).to redirect_to(admin_assessment_periods_path)
        expect(flash[:notice]).to be_present
      end

      it "does not create assessment_period with duplicate year and calendar_number" do
        create(:assessment_period, year: valid_params[:assessment_period][:calendar_year], quarter_number: valid_params[:assessment_period][:calendar_number])
        expect {
          post admin_assessment_periods_path, params: valid_params
        }.not_to change(AssessmentPeriod, :count)
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "renders form with errors when calendar_number is invalid" do
        invalid_params = {assessment_period: {calendar_year: assessment_period_year, calendar_number: 5, start_date: "#{assessment_period_year}-01-01", end_date: "#{assessment_period_year}-03-31"}}
        post admin_assessment_periods_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("calendar_number")
      end

      it "accepts past year" do
        past_params = {
          assessment_period: {
            calendar_year: 2020,
            calendar_number: 1,
            start_date: "2020-01-01",
            end_date: "2020-03-31",
            evaluation_start_date: "2020-04-01",
            evaluation_end_date: "2020-04-15"
          }
        }
        expect {
          post admin_assessment_periods_path, params: past_params
        }.to change(AssessmentPeriod, :count).by(1)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        post admin_assessment_periods_path, params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "GET /admin/assessment_periods/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get admin_assessment_period_path(draft_assessment_period)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response" do
        get admin_assessment_period_path(draft_assessment_period)
        expect(response).to be_successful
      end

      it "displays assessment_period details" do
        get admin_assessment_period_path(draft_assessment_period)
        expect(response.body).to include(draft_assessment_period.name)
        expect(response.body).to include(draft_assessment_period.status)
        expect(response.body).to match(/#{draft_assessment_period.start_date.day}|#{draft_assessment_period.start_date.strftime("%d")}/)
      end

      it "displays related metrics" do
        get admin_assessment_period_path(active_assessment_period)
        expect(response.body).to match(/skill_ratings|оценки|ratings/i)
      end

      it "displays status management buttons for draft assessment_period" do
        get admin_assessment_period_path(draft_assessment_period)
        expect(response.body).to match(/activate|активировать/i)
      end

      it "displays status management buttons for active assessment_period" do
        get admin_assessment_period_path(active_assessment_period)
        expect(response.body).to match(/close|закрыть/i)
      end

      it "displays status management buttons for closed assessment_period" do
        get admin_assessment_period_path(closed_assessment_period)
        expect(response.body).to match(/archive|архивировать/i)
      end

      it "returns 404 for non-existent assessment_period" do
        non_existent_id = (AssessmentPeriod.maximum(:id) || 0) + 999999
        get admin_assessment_period_path(non_existent_id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        get admin_assessment_period_path(draft_assessment_period)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "GET /admin/assessment_periods/:id/edit" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get edit_admin_assessment_period_path(draft_assessment_period)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response for draft assessment_period" do
        get edit_admin_assessment_period_path(draft_assessment_period)
        expect(response).to be_successful
      end

      it "displays edit form for draft assessment_period" do
        get edit_admin_assessment_period_path(draft_assessment_period)
        expect(response.body).to include("year")
        expect(response.body).to include(draft_assessment_period.start_date.year.to_s)
      end

      it "denies edit for active assessment_period" do
        get edit_admin_assessment_period_path(active_assessment_period)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end

      it "denies edit for closed assessment_period" do
        get edit_admin_assessment_period_path(closed_assessment_period)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end

      it "returns 404 for non-existent assessment_period" do
        non_existent_id = (AssessmentPeriod.maximum(:id) || 0) + 999999
        get edit_admin_assessment_period_path(non_existent_id)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        get edit_admin_assessment_period_path(draft_assessment_period)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "PUT /admin/assessment_periods/:id" do
    let(:valid_update_params) do
      {
        assessment_period: {
          description: "Updated description",
          start_date: draft_assessment_period.start_date,
          end_date: draft_assessment_period.end_date,
          evaluation_start_date: draft_assessment_period.evaluation_start_date,
          evaluation_end_date: draft_assessment_period.evaluation_end_date
        }
      }
    end

    context "when user is not authenticated" do
      it "redirects to sign in" do
        put admin_assessment_period_path(draft_assessment_period), params: valid_update_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated as admin" do
      before { sign_in admin, scope: :user }

      it "updates draft assessment_period with valid params" do
        put admin_assessment_period_path(draft_assessment_period), params: valid_update_params
        expect(draft_assessment_period.reload.description).to eq("Updated description")
      end

      it "redirects to show page with notice" do
        put admin_assessment_period_path(draft_assessment_period), params: valid_update_params
        expect(response).to redirect_to(admin_assessment_period_path(draft_assessment_period))
        expect(flash[:notice]).to be_present
      end

      it "renders form with errors when invalid" do
        invalid_params = {assessment_period: {end_date: draft_assessment_period.start_date - 1.day}}
        put admin_assessment_period_path(draft_assessment_period), params: invalid_params
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("error")
      end

      it "denies update for active assessment_period with authorization error" do
        put admin_assessment_period_path(active_assessment_period), params: valid_update_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end

      it "does not change active assessment_period data" do
        original_description = active_assessment_period.description
        put admin_assessment_period_path(active_assessment_period), params: valid_update_params
        expect(active_assessment_period.reload.description).to eq(original_description)
      end

      it "denies update for closed assessment_period with authorization error" do
        put admin_assessment_period_path(closed_assessment_period), params: valid_update_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end

      it "does not change closed assessment_period data" do
        original_description = closed_assessment_period.description
        put admin_assessment_period_path(closed_assessment_period), params: valid_update_params
        expect(closed_assessment_period.reload.description).to eq(original_description)
      end

      it "denies update for archived assessment_period with authorization error" do
        archived_assessment_period = create(:assessment_period, status: :archived)
        put admin_assessment_period_path(archived_assessment_period), params: valid_update_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end

      it "returns 404 for non-existent assessment_period" do
        non_existent_id = (AssessmentPeriod.maximum(:id) || 0) + 999999
        put admin_assessment_period_path(non_existent_id), params: valid_update_params
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        put admin_assessment_period_path(draft_assessment_period), params: valid_update_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "DELETE /admin/assessment_periods/:id" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "deletes draft assessment_period" do
        expect {
          delete admin_assessment_period_path(draft_assessment_period)
        }.to change(AssessmentPeriod, :count).by(-1)
      end

      it "redirects to index with notice" do
        delete admin_assessment_period_path(draft_assessment_period)
        expect(response).to redirect_to(admin_assessment_periods_path)
        expect(flash[:notice]).to be_present
      end

      it "denies destroy for active assessment_period" do
        delete admin_assessment_period_path(active_assessment_period)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        delete admin_assessment_period_path(draft_assessment_period)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end
end
