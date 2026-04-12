class Users::RegistrationsController < Devise::RegistrationsController
  protected

  def after_sign_up_path_for(resource)
    resource.team ? team_path(resource.team) : teams_path
  end
end
