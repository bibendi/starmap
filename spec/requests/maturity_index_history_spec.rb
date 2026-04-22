# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MaturityIndexHistory", type: :request do
  let_it_be(:team) { create(:team) }
  let_it_be(:technology) { create(:technology) }

  before do
    create(:team_technology, team: team, technology: technology, target_experts: 1)
  end

  describe "GET /maturity_index_history" do
    context "when authenticated as admin" do
      let(:admin) { create(:admin) }

      before { sign_in admin }

      context "with valid team_ids" do
        let(:quarter) { create(:quarter, status: :active) }

        before do
          create(:skill_rating, user: create(:user, team: team), technology: technology, quarter: quarter, rating: 2, team: team)
        end

        it "returns 200 with history data" do
          get maturity_index_history_path, params: {team_ids: [team.id]}

          expect(response).to have_http_status(:ok)
          json = response.parsed_body
          expect(json).to have_key("history")
          expect(json["history"]).to be_an(Array)
          expect(json["history"].first).to include("quarter_name" => quarter.full_name, "maturity_index" => a_kind_of(Numeric))
        end
      end

      context "with empty team_ids" do
        it "returns 400" do
          get maturity_index_history_path, params: {team_ids: []}

          expect(response).to have_http_status(:bad_request)
        end
      end

      context "without team_ids param" do
        it "returns 400" do
          get maturity_index_history_path

          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    context "when unauthenticated" do
      it "redirects to sign in" do
        get maturity_index_history_path, params: {team_ids: [team.id]}

        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when unauthorized" do
      let(:engineer) { create(:engineer) }

      before { sign_in engineer }

      it "raises NotAuthorizedError" do
        expect {
          get maturity_index_history_path, params: {team_ids: [team.id]}
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
