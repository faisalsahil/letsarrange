class EmailVerificationsController < Devise::ConfirmationsController
  before_filter :check_owner, only: :create
  before_filter :authenticate_user!, only: :show

  # POST /resource/confirmation
  def create
    self.resource = resource_class.send_confirmation_instructions(resource_params)
    yield resource if block_given?

    if successfully_sent?(resource)
      flash.now[:notice] = 'You will receive an email with instructions about how to verify your email in a few minutes'
    else
      flash.now[:error] = 'An error occurred when sending the verification email'
    end
    render 'common/update_flash'
  end

  # GET /resource/confirmation?confirmation_token=abcdef
  def show
    self.resource = resource_class.confirm_by_token(params[:confirmation_token])
    yield resource if block_given?

    if resource.errors.empty?
      set_flash_message(:notice, :confirmed)
    else
      flash[:error] = 'Confirmation token is invalid'
    end
    respond_with_navigational(resource){ redirect_to after_confirmation_path_for }
  end

  protected

  def after_confirmation_path_for
    contact_points_path
  end

  def check_owner
    cp = ContactPoint.find_by!(params.require(:contact_point).permit(:description))
    render status: :unauthorized unless cp.user == current_user
  end

  def authenticate_user!
    unless current_user
      store_location_for(:user, request.fullpath)
      flash[:notice] = 'Please login to confirm your email address'
    end
    super(force: true)

    #if there is a user signed in but he isn't the owner of the cp
    redirect_to contact_points_url unless current_user.contacts_email.find_by(confirmation_token:  Devise.token_generator.digest(ContactPoint, :confirmation_token, params[:confirmation_token]))
  end
end