class RegistrationsController < Devise::RegistrationsController
  include InModalDetector

  # before_filter :set_default_states, only: :create
  respond_to :js, :html
  layout 'application'
  helper_method :must_verify?

  def new
    head 404
  end

  # POST /resource
  def create
    build_resource(sign_up_params)

    if resource.save
      @voice = resource.contacts_voice.first
      @sms = resource.contacts_sms.first
      sign_up(resource_name, resource)
    else
      clean_up_passwords resource
      render :new
    end
  end

  def update
    account_update_params = devise_parameter_sanitizer.sanitize(:account_update)

    # required for settings form to submit when password is left blank
    if account_update_params[:password].blank?
      account_update_params.delete("password")
      account_update_params.delete("password_confirmation")
    end

    @user = User.find(current_user.id)
    if @user.update_attributes(account_update_params)
      set_flash_message :notice, :updated
      # Sign in the user bypassing validation in case his password changed
      sign_in @user, :bypass => true
      redirect_to after_update_path_for(@user)
    else
      render :edit
    end
  end
  
  protected

  def set_default_states
    params[:user][:sms_sent_to_user_state] = SmsSentToUserState::ONCE
  end

  def sign_up_params
    user_attrs = super
    cp_attrs = user_attrs.delete(:contact_information)
    @email = cp_attrs[:email].presence
    @phone = cp_attrs[:phone].presence
    @sms_capable = cp_attrs[:sms_capable] == '1'
    user_attrs[:contact_points_attributes] = []
    user_attrs[:contact_points_attributes] << { description: @email, type: 'ContactPoint::Email' } if @email
    if @phone
      user_attrs[:contact_points_attributes] << { description: @phone, type: 'ContactPoint::Voice' }
      user_attrs[:contact_points_attributes] << { description: @phone, type: 'ContactPoint::Sms' } if @sms_capable
    end
    user_attrs[:phone_missing] = @in_modal && !@phone
    user_attrs
  end

  def must_verify?
    @voice || @sms
  end
end