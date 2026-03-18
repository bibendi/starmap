# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Navigation menu", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:engineer) { create(:engineer) }

  describe "admin sidebar navigation" do
    context "when user is admin" do
      before do
        sign_in admin, scope: :user
        get admin_quarters_path
      end

      it "displays sidebar with admin navigation" do
        expect(response.body).to include("sidebar")
        expect(response.body).to include(I18n.t("admin.sidebar.sections.management"))
        expect(response.body).to include(admin_quarters_path)
      end
    end

    context "when user is unit_lead" do
      before do
        sign_in unit_lead, scope: :user
        get admin_quarters_path
      end

      it "displays sidebar with admin navigation" do
        expect(response.body).to include("sidebar")
        expect(response.body).to include(I18n.t("admin.sidebar.sections.management"))
        expect(response.body).to include(admin_quarters_path)
      end
    end

    context "when user is engineer" do
      before do
        sign_in engineer, scope: :user
        get engineer_path
      end

      it "does not display admin sidebar" do
        expect(response.body).not_to include("sidebar__section-title")
        expect(response.body).not_to include(admin_quarters_path)
      end
    end

    context "when user is not signed in" do
      it "does not display admin sidebar" do
        get new_user_session_path
        expect(response.body).not_to include("sidebar__section-title")
        expect(response.body).not_to include(admin_quarters_path)
      end
    end
  end
end
