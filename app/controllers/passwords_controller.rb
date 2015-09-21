class PasswordsController < Devise::PasswordsController
  before_filter :check_voice_completed, only: [:edit, :update]
  layout "application"

  # POST /resource/password
  def create
    token = resource_class.send_reset_password_instructions(resource_params)
    location = if voice_request?
                 voice_password_path(token)
               else
                 flash[:notice] = 'If these match a userid, you will receive instructions on how to reset your password'
                 after_sending_reset_password_instructions_path_for(resource_name)
               end
    respond_with({}, location: location)
  end

  def after_voice_reset
    @token = params[:token]
    @code = User.find_by_encrypted_token(@token).try(:voice_reset_code) || User.fake_code(@token)
  end

  private

  def voice_request?
    ['ContactPoint::Voice', 'voice'].include?(resource_params[:contact_point_for_reset][:type])
  end

  def check_voice_completed
    token = params[:reset_password_token] || params[:user][:reset_password_token]
    if User.fake_token?(token)
      prompt_for_voice_process(token)
    else
      user = User.find_by_encrypted_token(token)
      if user && user.voice_reset_in_progress?
        if user.voice_reset_active?
          prompt_for_voice_process(token)
        else
          redirect_to new_user_session_url, alert: 'Your password reset process has expired. Please request a new password reset'
        end
      end
    end
  end

  def prompt_for_voice_process(token)
    redirect_to voice_password_url(token), alert: 'You must first complete the validation process by calling to the corresponding phone number'
  end
end