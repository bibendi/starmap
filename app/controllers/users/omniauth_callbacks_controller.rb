class Users::OmniauthCallbacksController < Devise::OmniauthCallbacksController
  def oidc
    @user = User.from_omniauth(request.env["omniauth.auth"])
    session[:id_token] = request.env["omniauth.auth"].dig("credentials", "id_token")

    if @user.active_for_authentication?
      sign_in_and_redirect @user, event: :authentication
      set_flash_message(:notice, :success, kind: "OIDC") if is_navigational_format?
    else
      sign_out @user
      redirect_to root_path, alert: I18n.t("devise.failure.inactive")
    end
  end

  def failure
    redirect_to root_path, alert: failure_message
  end
end
