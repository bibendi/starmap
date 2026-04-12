# frozen_string_literal: true

require "rails_helper"

RSpec.describe SessionsController, type: :controller do
  describe "#destroy" do
    let(:user) { create(:user) }

    before do
      request.env["devise.mapping"] = Devise.mappings[:user]
      sign_in user, scope: :user
    end

    it "clears session id_token" do
      request.session[:id_token] = "test-token"
      request.session.delete(:id_token)
      expect(request.session[:id_token]).to be_nil
    end
  end
end
