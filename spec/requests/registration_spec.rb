# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Registration", type: :request do
  it "shows registration link on sign-in page" do
    get new_user_session_path

    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Зарегистрироваться")
  end

  it "allows user to register" do
    expect {
      post user_registration_path, params: {
        user: {
          email: "newuser@example.com",
          first_name: "New",
          last_name: "User",
          password: "password123",
          password_confirmation: "password123"
        }
      }
    }.to change(User, :count).by(1)

    expect(response).to redirect_to(teams_path)
    user = User.last
    expect(user.email).to eq("newuser@example.com")
    expect(user.first_name).to eq("New")
    expect(user.last_name).to eq("User")
  end
end
