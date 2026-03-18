# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Navigation menu", type: :request do
  let_it_be(:admin) { create(:admin) }
  let_it_be(:unit_lead) { create(:unit_lead) }
  let_it_be(:engineer) { create(:engineer) }

  describe "admin link in navigation" do
    context "when user is admin" do
      before do
        sign_in admin, scope: :user
        get admin_quarters_path
      end

      it "displays admin link with correct path" do
        expect(response.body).to include("Admin")
        expect(response.body).to include(admin_quarters_path)
      end
    end

    context "when user is unit_lead" do
      before do
        sign_in unit_lead, scope: :user
        get admin_quarters_path
      end

      it "displays admin link with correct path" do
        expect(response.body).to include("Admin")
        expect(response.body).to include(admin_quarters_path)
      end
    end

    context "when user is engineer" do
      before do
        sign_in engineer, scope: :user
        get engineer_path
      end

      it "does not display admin link" do
        expect(response.body).not_to include("Admin")
      end
    end

    context "when user is not signed in" do
      it "does not display admin link" do
        get new_user_session_path
        expect(response.body).not_to include("Admin")
      end
    end
  end
end
