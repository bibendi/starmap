require "rails_helper"

RSpec.describe LocalesController, type: :controller do
  describe "POST #switch" do
    context "with valid locale" do
      context "when switching to English" do
        it "sets the locale cookie" do
          post :switch, params: { locale: :en }
          expect(cookies[:locale]).to eq("en")
        end

        it "sets flash notice in current locale" do
          post :switch, params: { locale: :en }
          expect(flash[:notice]).to eq("Language switched to English")
        end

        it "redirects back with fallback to root" do
          request.env["HTTP_REFERER"] = "/team"
          post :switch, params: { locale: :en }
          expect(response).to redirect_to("/team")
        end

        it "redirects to root when no referer" do
          post :switch, params: { locale: :en }
          expect(response).to redirect_to(root_path)
        end
      end

      context "when switching to Russian" do
        before do
          I18n.locale = :ru
        end

        after do
          I18n.locale = :en
        end

        it "sets the locale cookie" do
          post :switch, params: { locale: :ru }
          expect(cookies[:locale]).to eq("ru")
        end

        it "sets flash notice in Russian" do
          post :switch, params: { locale: :ru }
          expect(flash[:notice]).to eq("Язык изменен на Русский")
        end
      end
    end

    context "with invalid locale" do
      it "does not set locale cookie" do
        post :switch, params: { locale: :fr }
        expect(cookies[:locale]).to be_nil
      end

      it "does not set flash notice" do
        post :switch, params: { locale: :fr }
        expect(flash[:notice]).to be_nil
      end

      it "still redirects back" do
        request.env["HTTP_REFERER"] = "/team"
        post :switch, params: { locale: :fr }
        expect(response).to redirect_to("/team")
      end
    end

    context "with string locale parameter" do
      it "handles string 'en'" do
        post :switch, params: { locale: "en" }
        expect(cookies[:locale]).to eq("en")
      end

      it "handles string 'ru'" do
        post :switch, params: { locale: "ru" }
        expect(cookies[:locale]).to eq("ru")
      end
    end

    describe "Pundit authorization" do
      it "does not require authorization" do
        expect { post :switch, params: { locale: :en } }.not_to raise_error
      end
    end
  end

  describe "without authentication" do
    it "allows locale switching for unauthenticated users" do
      post :switch, params: { locale: :en }
      expect(response).to redirect_to(root_path)
      expect(cookies[:locale]).to eq("en")
    end
  end
end