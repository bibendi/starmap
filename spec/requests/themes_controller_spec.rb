require "rails_helper"

RSpec.describe ThemesController, type: :request do
  describe "POST /theme/:theme" do
    let_it_be(:user) { create(:user) }

    before do
      sign_in user, scope: :user
    end

    context "with valid theme" do
      it "sets the theme cookie and redirects back" do
        post switch_theme_path(:dark)

        expect(response).to redirect_to(root_path)
        expect(cookies[:theme]).to eq("dark")
        expect(flash[:notice]).to eq(I18n.t("theme.switched.dark"))
      end

      it "supports light theme" do
        post switch_theme_path(:light)

        expect(response).to redirect_to(root_path)
        expect(cookies[:theme]).to eq("light")
        expect(flash[:notice]).to eq(I18n.t("theme.switched.light"))
      end

      it "supports system theme" do
        post switch_theme_path(:system)

        expect(response).to redirect_to(root_path)
        expect(cookies[:theme]).to eq("system")
        expect(flash[:notice]).to eq(I18n.t("theme.switched.system"))
      end
    end

    context "with invalid theme" do
      it "does not set cookie and redirects back" do
        post switch_theme_path(:invalid)

        expect(response).to redirect_to(root_path)
        expect(cookies[:theme]).to be_nil
        expect(flash[:notice]).to be_nil
      end
    end

    it "sets cookie expiration to 1 year" do
      post switch_theme_path(:dark)

      cookies = response.headers["Set-Cookie"]
      theme_cookie = cookies.find { |c| c.include?("theme=") }
      expect(theme_cookie).to match(/expires=.*#{1.year.from_now.year}/)
    end
  end
end
