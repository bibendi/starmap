require "rails_helper"

RSpec.describe "Admin::TeamTechnologies", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:engineer) { create(:engineer) }
  let_it_be(:unit) { create(:unit) }
  let_it_be(:other_unit) { create(:unit) }
  let_it_be(:team) { create(:team, unit: unit) }
  let_it_be(:other_team) { create(:team, unit: other_unit) }
  let_it_be(:technology) { create(:technology, name: "Ruby") }

  describe "GET /admin/teams/:id (team technologies section)" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "displays technologies table on team show page" do
        create(:team_technology, team: team, technology: technology)
        get admin_team_path(team)
        expect(response.body).to include("Ruby")
      end

      it "displays empty state when no technologies assigned" do
        get admin_team_path(team)
        expect(response.body).to include(I18n.t("admin.team_technologies.empty_state"))
      end

      it "displays criticality badge" do
        create(:team_technology, team: team, technology: technology, criticality: "high")
        get admin_team_path(team)
        expect(response.body).to include("High")
      end
    end

    context "when user is unit lead" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "sees technologies for their unit's team" do
        create(:team_technology, team: team, technology: technology)
        get admin_team_path(team)
        expect(response).to be_successful
        expect(response.body).to include("Ruby")
      end

      it "denies access for team in another unit" do
        expect {
          get admin_team_path(other_team)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          get admin_team_path(team)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/teams/:id/team_technologies/new" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response within turbo frame" do
        get new_admin_team_team_technology_path(team)
        expect(response).to be_successful
      end
    end

    context "when user is unit lead for their unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "returns successful response" do
        get new_admin_team_team_technology_path(team)
        expect(response).to be_successful
      end
    end

    context "when user is unit lead for another unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "denies access" do
        expect {
          get new_admin_team_team_technology_path(other_team)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "POST /admin/teams/:id/team_technologies" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "creates team technology and redirects with notice" do
        expect {
          post admin_team_team_technologies_path(team), params: {
            team_technology: {technology_id: technology.id}
          }
        }.to change(TeamTechnology, :count).by(1)

        expect(response).to redirect_to(admin_team_path(team))
        expect(flash[:notice]).to eq(I18n.t("admin.team_technologies.created"))
      end

      it "shows new technology on team show page" do
        post admin_team_team_technologies_path(team), params: {
          team_technology: {technology_id: technology.id}
        }
        follow_redirect!
        expect(response.body).to include("Ruby")
      end

      it "prevents duplicate technology" do
        create(:team_technology, team: team, technology: technology)

        expect {
          post admin_team_team_technologies_path(team), params: {
            team_technology: {technology_id: technology.id}
          }
        }.not_to change(TeamTechnology, :count)
      end
    end

    context "when user is unit lead for their unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "creates team technology" do
        expect {
          post admin_team_team_technologies_path(team), params: {
            team_technology: {technology_id: technology.id}
          }
        }.to change(TeamTechnology, :count).by(1)
      end
    end

    context "when user is unit lead for another unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "denies access" do
        expect {
          post admin_team_team_technologies_path(other_team), params: {
            team_technology: {technology_id: technology.id}
          }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end

    context "when user is engineer" do
      before { sign_in engineer, scope: :user }

      it "denies access" do
        expect {
          post admin_team_team_technologies_path(team), params: {
            team_technology: {technology_id: technology.id}
          }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "GET /admin/teams/:id/team_technologies/:id/edit" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "returns successful response within turbo frame" do
        tt = create(:team_technology, team: team, technology: technology)
        get edit_admin_team_team_technology_path(team, tt)
        expect(response).to be_successful
      end
    end

    context "when user is unit lead for their unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "returns successful response" do
        tt = create(:team_technology, team: team, technology: technology)
        get edit_admin_team_team_technology_path(team, tt)
        expect(response).to be_successful
      end
    end

    context "when user is unit lead for another unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "denies access" do
        other_tt = create(:team_technology, team: other_team)
        expect {
          get edit_admin_team_team_technology_path(other_team, other_tt)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "PATCH /admin/teams/:id/team_technologies/:id" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "updates criticality and target_experts" do
        tt = create(:team_technology, team: team, technology: technology)
        patch admin_team_team_technology_path(team, tt), params: {
          team_technology: {criticality: "high", target_experts: 5}
        }
        tt.reload
        expect(tt.criticality).to eq("high")
        expect(tt.target_experts).to eq(5)
        expect(response).to redirect_to(admin_team_path(team))
        expect(flash[:notice]).to eq(I18n.t("admin.team_technologies.updated"))
      end

      it "shows validation error for invalid target_experts" do
        tt = create(:team_technology, team: team, technology: technology)
        patch admin_team_team_technology_path(team, tt), params: {
          team_technology: {target_experts: 0}
        }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "shows validation error for negative target_experts" do
        tt = create(:team_technology, team: team, technology: technology)
        patch admin_team_team_technology_path(team, tt), params: {
          team_technology: {target_experts: -1}
        }
        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when user is unit lead for their unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "updates team technology" do
        tt = create(:team_technology, team: team, technology: technology)
        patch admin_team_team_technology_path(team, tt), params: {
          team_technology: {criticality: "low", target_experts: 1}
        }
        tt.reload
        expect(tt.criticality).to eq("low")
      end
    end

    context "when user is unit lead for another unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "denies access" do
        other_tt = create(:team_technology, team: other_team)
        expect {
          patch admin_team_team_technology_path(other_team, other_tt), params: {
            team_technology: {criticality: "high", target_experts: 5}
          }
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end

  describe "DELETE /admin/teams/:id/team_technologies/:id" do
    context "when user is admin" do
      before { sign_in admin, scope: :user }

      it "destroys team technology and redirects with notice" do
        tt = create(:team_technology, team: team, technology: technology)
        expect {
          delete admin_team_team_technology_path(team, tt)
        }.to change(TeamTechnology, :count).by(-1)

        expect(response).to redirect_to(admin_team_path(team))
        expect(flash[:notice]).to eq(I18n.t("admin.team_technologies.destroyed"))
      end

      it "technology no longer appears in list" do
        tt = create(:team_technology, team: team, technology: technology)
        delete admin_team_team_technology_path(team, tt)
        follow_redirect!
        expect(response.body).not_to include("Ruby")
      end

      it "prevents destroy when skill ratings exist" do
        tt = create(:team_technology, team: team, technology: technology)
        create(:skill_rating, team: team, technology: technology, user: create(:engineer, team: team), quarter: create(:quarter))

        expect {
          delete admin_team_team_technology_path(team, tt)
        }.not_to change(TeamTechnology, :count)

        expect(response).to redirect_to(admin_team_path(team))
        expect(flash[:alert]).to eq(I18n.t("admin.team_technologies.cannot_delete_with_ratings"))
      end
    end

    context "when user is unit lead for their unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "destroys team technology" do
        tt = create(:team_technology, team: team, technology: technology)
        expect {
          delete admin_team_team_technology_path(team, tt)
        }.to change(TeamTechnology, :count).by(-1)
      end
    end

    context "when user is unit lead for another unit" do
      let(:unit_lead) { create(:unit_lead, team: nil) }

      before do
        unit.update!(unit_lead: unit_lead)
        sign_in unit_lead, scope: :user
      end

      it "denies access" do
        other_tt = create(:team_technology, team: other_team)
        expect {
          delete admin_team_team_technology_path(other_team, other_tt)
        }.to raise_error(Pundit::NotAuthorizedError)
      end
    end
  end
end
