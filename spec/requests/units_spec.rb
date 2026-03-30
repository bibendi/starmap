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

  describe "GET /units/:id" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get unit_path(unit)
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "with id parameter" do
        before { sign_in unit_lead, scope: :user }

        it "returns successful response for specified unit" do
          get unit_path(unit)
          expect(response).to be_successful
        end

        context "when user does not have access to the unit" do
          let(:other_unit) { create(:unit) }

          it "denies access" do
            expect {
              get unit_path(other_unit)
            }.to raise_error(Pundit::NotAuthorizedError)
          end
        end
      end

      context "with inactive user" do
        let(:inactive_unit_lead) { create(:unit_lead, active: false) }

        before { sign_in inactive_unit_lead, scope: :user }

        it "redirects to sign in" do
          get unit_path(unit)
          expect(response).to redirect_to(new_user_session_path)
        end
      end

      context "as admin" do
        before { sign_in admin, scope: :user }

        it "allows access to any unit with id parameter" do
          get unit_path(unit)
          expect(response).to be_successful
        end
      end

      context "as engineer" do
        before { sign_in engineer, scope: :user }

        it "denies access" do
          expect {
            get unit_path(unit)
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end

      context "as team lead" do
        before { sign_in team_lead, scope: :user }

        it "denies access" do
          expect {
            get unit_path(unit)
          }.to raise_error(Pundit::NotAuthorizedError)
        end
      end
    end
  end

  describe "GET /units" do
    context "when user is not authenticated" do
      it "redirects to sign in" do
        get units_path
        expect(response).to redirect_to(new_user_session_path)
      end
    end

    context "when user is authenticated" do
      context "as unit lead with unit" do
        before do
          unit.update(unit_lead: unit_lead)
          sign_in unit_lead, scope: :user
        end

        it "returns successful response" do
          get units_path
          expect(response).to be_successful
        end

        it "displays user's unit in list" do
          get units_path
          expect(response.body).to include(unit.name)
        end
      end

      context "as unit lead without unit" do
        let(:unit_lead_without_unit) { create(:unit_lead) }

        before { sign_in unit_lead_without_unit, scope: :user }

        it "returns successful response" do
          get units_path
          expect(response).to be_successful
        end

        it "shows empty state message" do
          get units_path
          expect(response.body).to include(I18n.t("units.index.empty.title"))
        end
      end

      context "as admin" do
        before { sign_in admin, scope: :user }

        it "returns successful response" do
          get units_path
          expect(response).to be_successful
        end

        it "displays all units" do
          get units_path
          expect(response.body).to include(unit.name)
        end
      end

      context "as engineer" do
        before { sign_in engineer, scope: :user }

        it "returns successful response" do
          get units_path
          expect(response).to be_successful
        end

        it "shows empty state message" do
          get units_path
          expect(response.body).to include(I18n.t("units.index.empty.title"))
        end
      end

      context "as team lead" do
        before { sign_in team_lead, scope: :user }

        it "returns successful response" do
          get units_path
          expect(response).to be_successful
        end

        it "shows empty state message" do
          get units_path
          expect(response.body).to include(I18n.t("units.index.empty.title"))
        end
      end

      context "with pagination" do
        before do
          sign_in admin, scope: :user
          create_list(:unit, 25)
        end

        it "paginates results" do
          get units_path
          expect(response.body).to include('class="pagination"')
        end

        it "shows second page" do
          get units_path, params: {page: 2}
          expect(response).to be_successful
        end
      end
    end
  end
end
