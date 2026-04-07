require "rails_helper"

RSpec.describe "Teams", type: :request do
  let_it_be(:unit) { create(:unit) }
  let_it_be(:team) { create(:team, unit: unit) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:team_lead) { create(:team_lead, team: team) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:current_quarter) { create(:quarter, :current) }
  let_it_be(:unit_for_unit_lead) { create(:unit, unit_lead: unit_lead) }
  let_it_be(:unit_lead_team) { create(:team, unit: unit_for_unit_lead) }

  before do
    team.update(team_lead: team_lead)
  end

  describe "GET /" do
    context "when user has a team" do
      before { sign_in unit_lead, scope: :user }

      it "renders user's team page" do
        get "/"
        expect(response).to be_successful
      end
    end

    context "when user has no team" do
      let(:user_without_team) { create(:engineer, team: nil) }

      before { sign_in user_without_team, scope: :user }

      it "redirects to teams list" do
        get "/"
        expect(response).to redirect_to(teams_path)
      end
    end
  end

  describe "GET /teams/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get team_path(team)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "with user's team" do
        before { sign_in engineer, scope: :user }

        it "returns successful response" do
          get team_path(team)
          expect(response).to be_successful
        end

        it "renders team dashboard" do
          get team_path(team)
          expect(response).to be_successful
        end
      end

      context "when user does not have access to the team" do
        let(:other_team) { create(:team) }

        before { sign_in engineer, scope: :user }

        it "denies access" do
          expect {
            get team_path(other_team)
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "with inactive user" do
        let(:inactive_engineer) { create(:engineer, active: false, team: team) }

        before { sign_in inactive_engineer, scope: :user }

        it "redirects to sign in" do
          get team_path(team)
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "as unit lead" do
        before { sign_in unit_lead, scope: :user }

        it "allows access to any team" do
          get team_path(team)
          expect(response).to be_successful
        end
      end

      context "as admin" do
        before { sign_in admin, scope: :user }

        it "allows access to any team" do
          get team_path(team)
          expect(response).to be_successful
        end
      end
    end
  end

  describe "GET /teams" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get teams_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "as engineer with team" do
        before { sign_in engineer, scope: :user }

        it "returns successful response" do
          get teams_path
          expect(response).to be_successful
        end

        it "displays user's team in list" do
          get teams_path
          expect(response.body).to include(team.name)
        end
      end

      context "as engineer without team" do
        let(:user_without_team) { create(:engineer, team: nil) }

        before { sign_in user_without_team, scope: :user }

        it "returns successful response" do
          get teams_path
          expect(response).to be_successful
        end

        it "shows empty state message" do
          get teams_path
          expect(response.body).to include(I18n.t("teams.index.empty.title"))
        end
      end

      context "as team lead without team" do
        let(:team_lead_without_team) { create(:team_lead, team: nil) }

        before { sign_in team_lead_without_team, scope: :user }

        it "returns successful response" do
          get teams_path
          expect(response).to be_successful
        end

        it "shows empty state message" do
          get teams_path
          expect(response.body).to include(I18n.t("teams.index.empty.title"))
        end
      end

      context "as unit lead" do
        before { sign_in unit_lead, scope: :user }

        it "returns successful response" do
          get teams_path
          expect(response).to be_successful
        end

        it "displays all teams" do
          get teams_path
          expect(response.body).to include(team.name)
          expect(response.body).to include(unit_lead_team.name)
        end
      end

      context "as admin" do
        before { sign_in admin, scope: :user }

        it "returns successful response" do
          get teams_path
          expect(response).to be_successful
        end

        it "displays all teams" do
          get teams_path
          expect(response.body).to include(team.name)
        end
      end

      context "with pagination" do
        before do
          sign_in admin, scope: :user
          create_list(:team, 25, unit: unit)
        end

        it "paginates results to 20 per page" do
          get teams_path
          expect(response.body).to include('class="pagination"')
        end

        it "shows second page" do
          get teams_path, params: {page: 2}
          expect(response).to be_successful
        end
      end
    end
  end
end
