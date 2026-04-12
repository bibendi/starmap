# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registration", type: :request do
  context "when REGISTRATION_ENABLED is false" do
    it "does not show registration link on sign-in page" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include("Зарегистрироваться")
    end
  end
end
