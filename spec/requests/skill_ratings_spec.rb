require "rails_helper"

RSpec.describe "SkillRatings", type: :request do
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:unit) { create(:unit, unit_lead: unit_lead) }
  let_it_be(:team) { create(:team, unit: unit) }
  let_it_be(:other_team) { create(:team, unit: unit) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:other_engineer) { create(:engineer, team: other_team) }
  let_it_be(:team_lead) { create(:team_lead, team: team) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer_without_team) { create(:engineer, team: nil) }

  let_it_be(:quarter) { create(:quarter, :current, status: "active") }
  let_it_be(:technology) { create(:technology) }
  let_it_be(:team_technology) { create(:team_technology, team: team, technology: technology) }

  describe "GET /users/:user_id/skill_ratings (show)" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get user_skill_ratings_path(engineer)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when authenticated as engineer" do
      before { sign_in engineer, scope: :user }

      it "shows own ratings page" do
        get user_skill_ratings_path(engineer)
        expect(response).to be_successful
      end

      it "denies access to other team's ratings" do
        get user_skill_ratings_path(other_engineer)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end

      it "redirects when user has no team" do
        get user_skill_ratings_path(engineer_without_team)
        expect(response).to redirect_to(user_path(engineer_without_team))
        expect(flash[:alert]).to eq(I18n.t("skill_ratings.errors.no_team"))
      end
    end

    context "when authenticated as team lead" do
      before { sign_in team_lead, scope: :user }

      it "shows team member's ratings" do
        get user_skill_ratings_path(engineer)
        expect(response).to be_successful
      end

      it "denies access to other team's ratings" do
        get user_skill_ratings_path(other_engineer)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end

    context "when authenticated as unit lead or admin" do
      it "allows unit lead to view any ratings" do
        sign_in unit_lead, scope: :user
        get user_skill_ratings_path(other_engineer)
        expect(response).to be_successful
      end

      it "allows admin to view any ratings" do
        sign_in admin, scope: :user
        get user_skill_ratings_path(other_engineer)
        expect(response).to be_successful
      end
    end

    context "with existing ratings" do
      let_it_be(:skill_rating) { create(:skill_rating, :draft, user: engineer, technology: technology, quarter: quarter, team: team, rating: 2) }

      before { sign_in engineer, scope: :user }

      it "displays ratings with status and level" do
        get user_skill_ratings_path(engineer)
        expect(response.body).to include(skill_rating.rating.to_s, I18n.t("skill_ratings.levels.two"), I18n.t("skill_ratings.status.#{skill_rating.status}"))
      end
    end

    context "with edit button" do
      before { sign_in engineer, scope: :user }

      it "shows edit button during evaluation period" do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
        get user_skill_ratings_path(engineer)
        expect(response.body).to include(I18n.t("skill_ratings.show.edit_button"))
      end

      it "hides edit button outside evaluation period" do
        allow(Date).to receive(:current).and_return(quarter.evaluation_end_date + 1.day)
        get user_skill_ratings_path(engineer)
        expect(response.body).not_to include(I18n.t("skill_ratings.show.edit_button"))
      end
    end
  end

  describe "GET /users/:user_id/skill_ratings/edit" do
    context "when not authenticated" do
      it "redirects to sign in" do
        get edit_user_skill_ratings_path(engineer)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "during evaluation period" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
      end

      it "allows engineer to edit own ratings" do
        sign_in engineer, scope: :user
        get edit_user_skill_ratings_path(engineer)
        expect(response).to be_successful
      end

      it "denies team lead access to team member's ratings" do
        sign_in team_lead, scope: :user
        get edit_user_skill_ratings_path(engineer)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end

      it "denies team lead access to other team's ratings" do
        sign_in team_lead, scope: :user
        get edit_user_skill_ratings_path(other_engineer)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end

    context "outside evaluation period" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_end_date + 1.day)
        sign_in engineer, scope: :user
      end

      it "redirects with alert" do
        get edit_user_skill_ratings_path(engineer)
        expect(response).to redirect_to(user_path(engineer))
        expect(flash[:alert]).to eq(I18n.t("skill_ratings.errors.not_evaluation_period"))
      end
    end

    context "when user has no team" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
        sign_in engineer_without_team, scope: :user
      end

      it "redirects with alert" do
        get edit_user_skill_ratings_path(engineer_without_team)
        expect(response).to redirect_to(user_path(engineer_without_team))
        expect(flash[:alert]).to eq(I18n.t("skill_ratings.errors.no_team"))
      end
    end
  end

  describe "POST /users/:user_id/skill_ratings/submit" do
    let_it_be(:new_technology) { create(:technology, sort_order: 2) }
    let_it_be(:new_team_technology) { create(:team_technology, team: team, technology: new_technology) }
    let_it_be(:submit_submitted_rating) { create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team, rating: 2) }
    let_it_be(:submit_draft_rating) { create(:skill_rating, :draft, user: engineer, technology: new_technology, quarter: quarter, team: team, rating: 1) }
    let_it_be(:other_team_technology) { create(:team_technology, team: other_team, technology: technology) }
    let_it_be(:other_submitted_rating) { create(:skill_rating, :submitted, user: other_engineer, technology: technology, quarter: quarter, team: other_team, rating: 2) }
    let_it_be(:rejected_engineer) { create(:engineer, team: team) }
    let_it_be(:rejected_rating) { create(:skill_rating, :rejected, user: rejected_engineer, technology: technology, quarter: quarter, team: team, rating: 1) }
    let_it_be(:rejected_engineer_draft) { create(:skill_rating, :draft, user: rejected_engineer, technology: new_technology, quarter: quarter, team: team, rating: 1) }

    context "when starmap has submitted and draft ratings" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
        sign_in engineer, scope: :user
      end

      it "submits only draft ratings" do
        post submit_user_skill_ratings_path(engineer)

        expect(response).to redirect_to(user_skill_ratings_path(engineer))
        expect(flash[:notice]).to eq(I18n.t("skill_ratings.submit.success"))
        expect(submit_draft_rating.reload).to be_submitted
        expect(submit_submitted_rating.reload).to be_submitted
      end
    end

    context "when there are no draft ratings" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
        sign_in other_engineer, scope: :user
      end

      it "redirects with alert and keeps ratings submitted" do
        post submit_user_skill_ratings_path(other_engineer)

        expect(response).to redirect_to(user_skill_ratings_path(other_engineer))
        expect(flash[:alert]).to eq(I18n.t("skill_ratings.submit.no_drafts"))
        expect(other_submitted_rating.reload).to be_submitted
      end
    end

    context "when there is a rejected rating" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
        sign_in rejected_engineer, scope: :user
      end

      it "redirects with alert and changes nothing" do
        post submit_user_skill_ratings_path(rejected_engineer)

        expect(response).to redirect_to(user_skill_ratings_path(rejected_engineer))
        expect(flash[:alert]).to eq(I18n.t("skill_ratings.submit.has_rejected"))
        expect(rejected_rating.reload).to be_rejected
        expect(rejected_engineer_draft.reload).to be_draft
      end
    end

    context "when engineer submits for another user" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
        sign_in other_engineer, scope: :user
      end

      it "denies access" do
        post submit_user_skill_ratings_path(engineer)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
        expect(submit_draft_rating.reload).to be_draft
        expect(submit_submitted_rating.reload).to be_submitted
      end
    end
  end

  describe "POST /users/:user_id/skill_ratings/:id/approve" do
    let_it_be(:submitted_rating) { create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team, rating: 2) }

    context "when not authenticated" do
      it "redirects to sign in" do
        post approve_user_skill_rating_path(engineer, submitted_rating)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "as team lead of engineer's team" do
      before { sign_in team_lead, scope: :user }

      it "approves the rating" do
        post approve_user_skill_rating_path(engineer, submitted_rating)
        submitted_rating.reload
        expect(submitted_rating).to have_attributes(
          status: "approved",
          approved_by: team_lead
        )
      end

      it "returns turbo stream" do
        post approve_user_skill_rating_path(engineer, submitted_rating), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "as unit lead" do
      before { sign_in unit_lead, scope: :user }

      it "denies approving engineer rating" do
        post approve_user_skill_rating_path(engineer, submitted_rating)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end

      it "approves team lead rating" do
        tl_rating = create(:skill_rating, :submitted, user: team_lead, technology: technology, quarter: quarter, team: team, rating: 2)
        post approve_user_skill_rating_path(team_lead, tl_rating)
        tl_rating.reload
        expect(tl_rating.status).to eq("approved")
      end
    end

    context "as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        post approve_user_skill_rating_path(engineer, submitted_rating)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end

    context "when rating is not submitted" do
      let_it_be(:other_technology) { create(:technology) }
      let_it_be(:draft_rating) { create(:skill_rating, :draft, user: engineer, technology: other_technology, quarter: quarter, team: team, rating: 1) }

      before { sign_in team_lead, scope: :user }

      it "redirects with alert" do
        post approve_user_skill_rating_path(engineer, draft_rating)
        expect(response).to redirect_to(user_skill_ratings_path(engineer))
        expect(flash[:alert]).to eq(I18n.t("skill_ratings.approve.already_processed"))
      end
    end
  end

  describe "POST /users/:user_id/skill_ratings/:id/reject" do
    let_it_be(:submitted_rating) { create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team, rating: 2) }

    context "as team lead" do
      before { sign_in team_lead, scope: :user }

      it "rejects the rating" do
        post reject_user_skill_rating_path(engineer, submitted_rating)
        submitted_rating.reload
        expect(submitted_rating).to have_attributes(
          status: "rejected",
          approved_by: team_lead
        )
      end

      it "returns turbo stream" do
        post reject_user_skill_rating_path(engineer, submitted_rating), as: :turbo_stream
        expect(response).to have_http_status(:ok)
        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end

    context "as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        post reject_user_skill_rating_path(engineer, submitted_rating)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "POST /users/:user_id/skill_ratings/approve_all" do
    context "as team lead" do
      before { sign_in team_lead, scope: :user }

      it "approves all submitted ratings for user in team" do
        rating1 = create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team, rating: 1)
        tech2 = create(:technology)
        create(:team_technology, team: team, technology: tech2)
        rating2 = create(:skill_rating, :submitted, user: engineer, technology: tech2, quarter: quarter, team: team, rating: 2)

        post approve_all_user_skill_ratings_path(engineer)

        [rating1, rating2].each { |r| r.reload }
        expect(rating1.status).to eq("approved")
        expect(rating2.status).to eq("approved")
      end

      it "redirects with success notice" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team, rating: 1)

        post approve_all_user_skill_ratings_path(engineer)
        expect(response).to redirect_to(user_skill_ratings_path(engineer))
        expect(flash[:notice]).to eq(I18n.t("skill_ratings.approve.all_success"))
      end

      it "redirects with alert when no submitted ratings" do
        create(:skill_rating, :draft, user: engineer, technology: technology, quarter: quarter, team: team, rating: 1)

        post approve_all_user_skill_ratings_path(engineer)
        expect(flash[:alert]).to eq(I18n.t("skill_ratings.approve.no_submitted"))
      end
    end

    context "as unit lead" do
      before { sign_in unit_lead, scope: :user }

      it "approves team lead ratings in own unit" do
        tl_rating = create(:skill_rating, :submitted, user: team_lead, technology: technology, quarter: quarter, team: team, rating: 2)

        post approve_all_user_skill_ratings_path(team_lead)
        tl_rating.reload
        expect(tl_rating.status).to eq("approved")
      end

      it "does not approve engineer ratings" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team, rating: 1)

        post approve_all_user_skill_ratings_path(engineer)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end

    context "as engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        create(:skill_rating, :submitted, user: engineer, technology: technology, quarter: quarter, team: team, rating: 1)

        post approve_all_user_skill_ratings_path(engineer)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end
  end

  describe "PATCH /users/:user_id/skill_ratings (update)" do
    let(:valid_params) do
      {
        ratings: {
          technology.id.to_s => {rating: "2"}
        }
      }
    end

    let(:empty_params) { {ratings: {}} }

    context "when not authenticated" do
      it "redirects to sign in" do
        patch user_skill_ratings_path(engineer), params: valid_params
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "during evaluation period" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
        sign_in engineer, scope: :user
      end

      it "creates new skill ratings" do
        expect {
          patch user_skill_ratings_path(engineer), params: valid_params
        }.to change(SkillRating, :count).by(1)
      end

      it "sets correct attributes" do
        patch user_skill_ratings_path(engineer), params: valid_params

        rating = SkillRating.find_by(user: engineer, technology: technology, quarter: quarter)
        expect(rating).to have_attributes(
          rating: 2,
          status: "draft",
          created_by: engineer,
          team: team
        )
      end

      it "redirects to show page with success message" do
        patch user_skill_ratings_path(engineer), params: valid_params
        expect(response).to redirect_to(user_skill_ratings_path(engineer))
        expect(flash[:notice]).to eq(I18n.t("skill_ratings.update.success"))
      end

      context "with existing rating" do
        let!(:existing_rating) { create(:skill_rating, :draft, user: engineer, technology: technology, quarter: quarter, team: team, rating: 0) }

        it "updates existing rating instead of creating new" do
          expect {
            patch user_skill_ratings_path(engineer), params: valid_params
          }.not_to change(SkillRating, :count)
        end

        it "updates rating value and updated_by" do
          patch user_skill_ratings_path(engineer), params: valid_params
          existing_rating.reload
          expect(existing_rating).to have_attributes(rating: 2, updated_by: engineer)
        end

        it "preserves original created_by" do
          original_creator = existing_rating.created_by
          patch user_skill_ratings_path(engineer), params: valid_params
          existing_rating.reload
          expect(existing_rating.created_by).to eq(original_creator)
        end
      end

      it "renders edit on empty params" do
        patch user_skill_ratings_path(engineer), params: empty_params
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "as team lead updating team member" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
        sign_in team_lead, scope: :user
      end

      it "denies access to team member" do
        patch user_skill_ratings_path(engineer), params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end

      it "denies access to other team" do
        patch user_skill_ratings_path(other_engineer), params: valid_params
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to eq(I18n.t("errors.not_authorized"))
      end
    end

    context "outside evaluation period" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_end_date + 1.day)
        sign_in engineer, scope: :user
      end

      it "redirects without updating" do
        expect {
          patch user_skill_ratings_path(engineer), params: valid_params
        }.not_to change(SkillRating, :count)

        expect(response).to redirect_to(user_path(engineer))
        expect(flash[:alert]).to eq(I18n.t("skill_ratings.errors.not_evaluation_period"))
      end
    end

    context "when user has no team" do
      before do
        allow(Date).to receive(:current).and_return(quarter.evaluation_start_date + 1.day)
        sign_in engineer_without_team, scope: :user
      end

      it "redirects without updating" do
        expect {
          patch user_skill_ratings_path(engineer_without_team), params: valid_params
        }.not_to change(SkillRating, :count)

        expect(response).to redirect_to(user_path(engineer_without_team))
        expect(flash[:alert]).to eq(I18n.t("skill_ratings.errors.no_team"))
      end
    end
  end
end
