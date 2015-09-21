class SessionsController < Devise::SessionsController
  include InModalDetector

  layout "devise"
  respond_to :js,:html
  helper_method :after_sign_in_path_for

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate(auth_options) || User.new_with_error(:base, 'Unknown userid and password')
    if resource && resource.persisted?
      set_flash_message(:notice, :signed_in)
      sign_in(resource_name, resource)
    else
      render :new
    end
  end
end