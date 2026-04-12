class SessionsController < Devise::SessionsController
  def destroy
    id_token = session.delete(:id_token)

    if id_token && OIDC_ENABLED
      sign_out(current_user)
      redirect_to oidc_end_session_url(id_token), allow_other_host: true
      return
    end

    super
  end

  private

  def oidc_end_session_url(id_token)
    uri = URI(ENV["OIDC_ISSUER"])
    uri.path = "#{uri.path}/protocol/openid-connect/logout"
    params = URI.encode_www_form(
      id_token_hint: id_token,
      post_logout_redirect_uri: new_user_session_url
    )
    "#{uri}?#{params}"
  end
end
