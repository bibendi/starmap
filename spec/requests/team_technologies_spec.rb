require "rails_helper"

RSpec.describe "TeamTechnologies", type: :request do
  let_it_be(:team) { create(:team) }
  let_it_be(:technology) { create(:technology, name: "Ruby") }
  let_it_be(:unrelated_technology) { create(:technology, name: "Go") }
  let_it_be(:team_technology) { create(:team_technology, team: team, technology: technology, target_experts: 2) }
  let_it_be(:current_quarter) { create(:quarter, :current) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:team_lead) { create(:team_lead, team: team) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:other_team) { create(:team) }
  let_it_be(:other_engineer) { create(:engineer, team: other_team) }

  describe "GET /teams/:team_id/technologies/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get team_technology_path(team, technology)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when technology is not associated with team" do
      before { sign_in admin, scope: :user }

      it "returns not found" do
        get team_technology_path(team, unrelated_technology)
        expect(response).to have_http_status(:not_found)
      end
    end

    context "when user is authorized" do
      before { sign_in team_lead, scope: :user }

      it "returns successful response" do
        get team_technology_path(team, technology)
        expect(response).to be_successful
      end

      it "displays technology name" do
        get team_technology_path(team, technology)
        expect(response.body).to include("Ruby")
      end

      it "displays team name link" do
        get team_technology_path(team, technology)
        expect(response.body).to include(team.name)
      end

      it "displays member names" do
        get team_technology_path(team, technology)
        expect(response.body).to include(engineer.full_name)
        expect(response.body).to include(team_lead.full_name)
      end

      it "displays legend" do
        get team_technology_path(team, technology)
        expect(response.body).to include("Can teach others")
      end
    end

    context "when no current quarter" do
      before do
        Quarter.where(is_current: true).update_all(is_current: false)
        sign_in team_lead, scope: :user
      end

      it "redirects to team page" do
        get team_technology_path(team, technology)
        expect(response).to redirect_to(team_path(team))
      end
    end

    context "when user is unauthorized" do
      before { sign_in other_engineer, scope: :user }

      it "returns error" do
        expect {
          get team_technology_path(team, technology)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
