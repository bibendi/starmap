require "rails_helper"

RSpec.describe "Teams", type: :request do
  let_it_be(:unit) { create(:unit) }
  let_it_be(:team) { create(:team, unit: unit) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:team_lead) { create(:team_lead, team: team) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:current_quarter) { create(:quarter, :current) }

  before do
    team.update(team_lead: team_lead)
  end

  describe "GET /team" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get team_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "without name parameter" do
        before { sign_in engineer, scope: :user }

        it "returns successful response" do
          get team_path
          expect(response).to be_successful
        end

        it "renders team dashboard" do
          get team_path
          expect(response).to be_successful
        end
      end

      context "with name parameter" do
        before { sign_in engineer, scope: :user }

        it "returns successful response for user's team" do
          get team_path, params: { name: team.name }
          expect(response).to be_successful
        end

        it "renders team dashboard" do
          get team_path, params: { name: team.name }
          expect(response).to be_successful
        end

        context "when user does not have access to the team" do
          let(:other_team) { create(:team) }

          it "denies access" do
            expect {
              get team_path, params: { name: other_team.name }
            }.to raise_error(Pundit::NotAuthorizedError)
          end
        end
      end

      context "when user has no team" do
        let(:user_without_team) { create(:engineer, team: nil) }

        before { sign_in user_without_team, scope: :user }

        it "raises Pundit::NotAuthorizedError" do
          expect {
            get team_path
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "with inactive user" do
        let(:inactive_engineer) { create(:engineer, active: false, team: team) }

        before { sign_in inactive_engineer, scope: :user }

        it "denies access" do
          expect {
            get team_path, params: { name: team.name }
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "as unit lead" do
        before { sign_in unit_lead, scope: :user }

        it "allows access to any team" do
          get team_path, params: { name: team.name }
          expect(response).to be_successful
        end
      end

      context "as admin" do
        before { sign_in admin, scope: :user }

        it "allows access to any team" do
          get team_path, params: { name: team.name }
          expect(response).to be_successful
        end
      end
    end
  end
end
