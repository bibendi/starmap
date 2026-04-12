# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Auth Strategy", type: :request do
  describe "sign-in page" do
    it "renders sign-in form" do
      get new_user_session_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Войти")
    end
  end
end
