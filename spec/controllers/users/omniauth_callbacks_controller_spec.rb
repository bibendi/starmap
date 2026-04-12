# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::OmniauthCallbacksController do
  describe "#failure" do
    it "redirects to root with alert" do
      allow(controller).to receive(:failure_message).and_return("Authentication failed")

      controller.failure

      expect(controller).to have_received(:redirect_to).with(root_path, alert: "Authentication failed")
    end
  end
end
