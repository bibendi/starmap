require "rails_helper"

RSpec.describe "Units", type: :request do
  let_it_be(:unit) { create(:unit) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:team_lead) { create(:team_lead) }

  before do
    unit.update(unit_lead: unit_lead)
  end

  describe "GET /unit" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get unit_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "without name parameter" do
        before { sign_in unit_lead, scope: :user }

        it "returns successful response" do
          get unit_path
          expect(response).to be_successful
        end
      end

      context "with name parameter" do
        before { sign_in unit_lead, scope: :user }

        it "returns successful response for specified unit" do
          get unit_path, params: {name: unit.name}
          expect(response).to be_successful
        end

        context "when user does not have access to the unit" do
          let(:other_unit) { create(:unit) }

          it "denies access" do
            expect {
              get unit_path, params: {name: other_unit.name}
            }.to raise_error(Pundit::NotAuthorizedError)
          end
        end
      end

      context "when user has no unit" do
        let(:unit_lead_without_unit) { create(:unit_lead) }

        before { sign_in unit_lead_without_unit, scope: :user }

        it "raises Pundit::NotAuthorizedError" do
          expect {
            get unit_path
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "with inactive user" do
        let(:inactive_unit_lead) { create(:unit_lead, active: false) }

        before { sign_in inactive_unit_lead, scope: :user }

        it "denies access" do
          expect {
            get unit_path, params: {name: unit.name}
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "as admin" do
        before { sign_in admin, scope: :user }

        it "allows access to any unit with name parameter" do
          get unit_path, params: {name: unit.name}
          expect(response).to be_successful
        end

        it "requires name parameter" do
          expect {
            get unit_path
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "as engineer" do
        before { sign_in engineer, scope: :user }

        it "denies access" do
          expect {
            get unit_path, params: {name: unit.name}
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "as team lead" do
        before { sign_in team_lead, scope: :user }

        it "denies access" do
          expect {
            get unit_path, params: {name: unit.name}
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end
  end
end
