require "rails_helper"

RSpec.describe "Locales", type: :request do
  describe "POST /locale/:locale" do
    context "with valid locale" do
      context "when switching to English" do
        it "sets the locale cookie" do
          post switch_locale_path(locale: :en)
          expect(cookies[:locale]).to eq("en")
        end

        it "sets flash notice in current locale" do
          post switch_locale_path(locale: :en)
          expect(flash[:notice]).to eq("Language switched to English")
        end

        it "redirects back with fallback to root" do
          post switch_locale_path(locale: :en), headers: {"HTTP_REFERER" => "/team"}
          expect(response).to redirect_to("/team")
        end

        it "redirects to root when no referer" do
          post switch_locale_path(locale: :en)
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
          post switch_locale_path(locale: :ru)
          expect(cookies[:locale]).to eq("ru")
        end

        it "sets flash notice in Russian" do
          post switch_locale_path(locale: :ru)
          expect(flash[:notice]).to eq("Язык изменен на Русский")
        end
      end
    end

    context "with invalid locale" do
      it "does not set locale cookie" do
        post switch_locale_path(locale: :fr)
        expect(cookies[:locale]).to be_nil
      end

      it "does not set flash notice" do
        post switch_locale_path(locale: :fr)
        expect(flash[:notice]).to be_nil
      end

      it "still redirects back" do
        post switch_locale_path(locale: :fr), headers: {"HTTP_REFERER" => "/team"}
        expect(response).to redirect_to("/team")
      end
    end

    context "with string locale parameter" do
      it "handles string 'en'" do
        post switch_locale_path(locale: "en")
        expect(cookies[:locale]).to eq("en")
      end

      it "handles string 'ru'" do
        post switch_locale_path(locale: "ru")
        expect(cookies[:locale]).to eq("ru")
      end
    end

    describe "Pundit authorization" do
      it "does not require authorization" do
        expect { post switch_locale_path(locale: :en) }.not_to raise_error
      end
    end
  end

  describe "without authentication" do
    it "allows locale switching for unauthenticated users" do
      post switch_locale_path(locale: :en)
      expect(response).to redirect_to(root_path)
      expect(cookies[:locale]).to eq("en")
    end
  end
end
