require "rails_helper"

RSpec.describe "Users", type: :request do
  let_it_be(:unit) { create(:unit) }
  let_it_be(:team) { create(:team, unit: unit) }
  let_it_be(:engineer) { create(:engineer, team: team) }
  let_it_be(:team_lead) { create(:team_lead, team: team) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:other_team) { create(:team) }
  let_it_be(:other_engineer) { create(:engineer, team: other_team) }

  before do
    unit.update(unit_lead: unit_lead)
  end

  describe "GET /users/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get user_path(engineer)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "viewing own profile" do
        before { sign_in engineer, scope: :user }

        it "returns successful response" do
          get user_path(engineer)
          expect(response).to be_successful
        end

        it "displays user's name" do
          get user_path(engineer)
          expect(response.body).to include(engineer.full_name)
        end

        it "displays team name" do
          get user_path(engineer)
          expect(response.body).to include(team.name)
        end

        it "displays unit name" do
          get user_path(engineer)
          expect(response.body).to include(unit.name)
        end
      end

      context "viewing other user's profile" do
        context "as engineer" do
          before { sign_in engineer, scope: :user }

          it "denies access to other engineer's profile" do
            expect {
              get user_path(other_engineer)
            }.to raise_error(Pundit::NotAuthorizedError)
          end

          it "allows access to own profile" do
            get user_path(engineer)
            expect(response).to be_successful
          end
        end

        context "as team lead" do
          before { sign_in team_lead, scope: :user }

          it "allows access to team member's profile" do
            get user_path(engineer)
            expect(response).to be_successful
          end

          it "denies access to other team's engineer" do
            expect {
              get user_path(other_engineer)
            }.to raise_error(Pundit::NotAuthorizedError)
          end
        end

        context "as unit lead" do
          before { sign_in unit_lead, scope: :user }

          it "allows access to any user's profile" do
            get user_path(engineer)
            expect(response).to be_successful
          end

          it "allows access to other unit's engineer" do
            get user_path(other_engineer)
            expect(response).to be_successful
          end
        end

        context "as admin" do
          before { sign_in admin, scope: :user }

          it "allows access to any user's profile" do
            get user_path(other_engineer)
            expect(response).to be_successful
          end
        end
      end

      context "when user has no team" do
        let(:user_without_team) { create(:engineer, team: nil) }

        before { sign_in user_without_team, scope: :user }

        it "returns successful response" do
          get user_path(user_without_team)
          expect(response).to be_successful
        end

        it "displays user's name" do
          get user_path(user_without_team)
          expect(response.body).to include(user_without_team.full_name)
        end

        it "does not display team or unit info" do
          get user_path(user_without_team)
          expect(response.body).not_to include(team.name)
        end
      end
    end
  end

  describe "POST /users/sign_in" do
    context "with inactive user" do
      let(:inactive_engineer) { create(:engineer, active: false, team: team) }

      it "prevents sign in and redirects back to sign in page with error" do
        post user_session_path, params: {
          user: {email: inactive_engineer.email, password: "password123"}
        }
        expect(response).to redirect_to(new_user_session_path)
        expect(flash[:alert]).to match(/not activated/i)
      end
    end
  end
end
