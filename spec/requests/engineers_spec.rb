require "rails_helper"

RSpec.describe "Engineers", type: :request do
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

  describe "GET /engineer" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get engineer_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "without id parameter (own profile)" do
        before { sign_in engineer, scope: :user }

        it "returns successful response" do
          get engineer_path
          expect(response).to be_successful
        end

        it "displays engineer's name" do
          get engineer_path
          expect(response.body).to include(engineer.full_name)
        end

        it "displays team name" do
          get engineer_path
          expect(response.body).to include(team.name)
        end

        it "displays unit name" do
          get engineer_path
          expect(response.body).to include(unit.name)
        end

        it "displays link to team" do
          get engineer_path
          expect(response.body).to include(team_path(name: team.name))
        end
      end

      context "with id parameter (viewing other engineer)" do
        context "as engineer" do
          before { sign_in engineer, scope: :user }

          it "denies access to other engineer's profile" do
            expect {
              get engineer_path, params: {id: other_engineer.id}
            }.to raise_error(Pundit::NotAuthorizedError)
          end

          it "allows access to own profile with id param" do
            get engineer_path, params: {id: engineer.id}
            expect(response).to be_successful
          end
        end

        context "as team lead" do
          before { sign_in team_lead, scope: :user }

          it "allows access to team member's profile" do
            get engineer_path, params: {id: engineer.id}
            expect(response).to be_successful
          end

          it "denies access to other team's engineer" do
            expect {
              get engineer_path, params: {id: other_engineer.id}
            }.to raise_error(Pundit::NotAuthorizedError)
          end
        end

        context "as unit lead" do
          before { sign_in unit_lead, scope: :user }

          it "allows access to unit member's profile" do
            get engineer_path, params: {id: engineer.id}
            expect(response).to be_successful
          end

          it "denies access to other unit's engineer" do
            expect {
              get engineer_path, params: {id: other_engineer.id}
            }.to raise_error(Pundit::NotAuthorizedError)
          end
        end

        context "as admin" do
          before { sign_in admin, scope: :user }

          it "allows access to any engineer's profile" do
            get engineer_path, params: {id: other_engineer.id}
            expect(response).to be_successful
          end
        end
      end

      context "with inactive user" do
        let(:inactive_engineer) { create(:engineer, active: false, team: team) }

        before { sign_in inactive_engineer, scope: :user }

        it "denies access" do
          expect {
            get engineer_path
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "when engineer has no team" do
        let(:engineer_without_team) { create(:engineer, team: nil) }

        before { sign_in engineer_without_team, scope: :user }

        it "returns successful response" do
          get engineer_path
          expect(response).to be_successful
        end

        it "displays engineer's name" do
          get engineer_path
          expect(response.body).to include(engineer_without_team.full_name)
        end

        it "does not display team or unit info" do
          get engineer_path
          expect(response.body).not_to include(team.name)
        end
      end
    end
  end
end
