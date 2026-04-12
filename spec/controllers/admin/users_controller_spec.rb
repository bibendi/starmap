# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::UsersController, type: :request do
  let_it_be(:admin_user) { create(:admin) }

  before do
    sign_in admin_user
  end

  describe "POST /admin/users" do
    it "creates user with password" do
      expect {
        post admin_users_path, params: {
          user: {
            email: "new@example.com",
            first_name: "New",
            last_name: "User",
            role: "engineer",
            active: true,
            password: "password123",
            password_confirmation: "password123"
          }
        }
      }.to change(User, :count).by(1)

      expect(response).to redirect_to(admin_users_path)
      user = User.last
      expect(user.email).to eq("new@example.com")
      expect(user.valid_password?("password123")).to be true
    end
  end
end
