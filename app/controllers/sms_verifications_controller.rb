class SmsVerificationsController < ApplicationController
  def new
    @contact_point = fetch_contact_point
    @contact_point.send_verification
    flash.now[:success] = 'The verification code has been sent'
    render_flash_only
  end

  def create
    @contact_point = fetch_contact_point
    @contact_point.verify!(params[:verification_code])
    if @contact_point.errors.empty?
      flash.now[:success] = 'Your phone number was successfully verified'
      if params[:success_url]
        render 'redirect'
      else
        render 'contact_points/refresh'
      end
    else
      flash.now[:error] = @contact_point.errors_sentence
      render 'failed_create'
    end
  end

  private

  def fetch_contact_point
    current_user.contact_points.find(params[:contact_point_id])
  end
end