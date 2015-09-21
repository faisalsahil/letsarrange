class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  before_filter :configure_devise_parameters, if: :devise_controller?
  before_filter :fetch_flash
  before_filter :authenticate_user!

  force_ssl if: :main_domain?

  protected

  def authenticate_admin!
    # redirect_to new_user_session_path, error: "This area is restricted to administrators only." unless current_user.try(:admin?)
    head 403 unless current_user.try(:admin?)
  end

  def after_sign_in_path_for(resource)
    resource.try(:admin?) ? admin_path : super
  end

  # Devise additional permitted parameters, for strong parameters in Rails 4
  def configure_devise_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:name, :uniqueid, :password, :password_confirmation, :sms_sent_to_user_state, :in_modal, contact_information: [:phone, :sms_capable, :email]) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:name, :uniqueid, :password, :current_password, :password_confirmation, :contact_point_for_reset) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :password, :remember_me, :in_modal) }
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || contact_points_path
  end

  def sign_in_by_url_mapping
    code = params.permit(:code)[:code]
    if code
      mapping = UrlMapping.fetch_mapping!(code)
      contact_point = mapping.contact_point
      case contact_point.status
      when ContactPointState::VERIFIED then sign_in_user(contact_point.user)
      when ContactPointState::DISABLED then authenticate_user!
      when ContactPointState::TRUSTED then verify_and_sign_in(contact_point)
      when ContactPointState::UNVERIFIED then verify_requiring_sign_in(contact_point)
      else
        fail
      end
    else
      authenticate_user!
    end
  end

  def fetch_flash
    %i(success alert error).each do |flash_type|
      flash.now[flash_type] = params[flash_type] if params[flash_type]
    end
  end

  def render_flash_only
    render 'common/update_flash', layout: false
  end

  def sign_in_user(user)
    sign_in(Devise::Mapping.find_scope!(user), user, event: :authentication)
  end

  def verify_and_sign_in(contact_point)
    contact_point.mark_as_verified!
    sign_in_user(contact_point.user)
  end

  def verify_requiring_sign_in(contact_point)
    if user_signed_in?
      if contact_point.user == current_user
        flash[:notice] = 'Your number was successfully verified' if contact_point.mark_as_verified!
      else
        redirect_to contact_points_url
      end
    else
      store_location_for(:user, request.fullpath)
      authenticate_user!
    end
  end

  def main_domain?
    Rails.env.production? && request.host_with_port == ENV['HOST_URL']
  end
end
