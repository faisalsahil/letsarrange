class VoiceVerificationsController < ApplicationController
  with_options only: :create do |f|
    f.skip_before_filter :verify_authenticity_token
    f.skip_before_filter :authenticate_user!
    f.http_basic_authenticate_with name: ENV['TWILIO_HTTP_USER'], password: ENV['TWILIO_HTTP_PASSWORD']
  end

  def new
    contact_point = fetch_contact_point
    @verification_code = contact_point.send_verification
    if params[:for_modal]
      @cancel_url = contact_point_voice_verification_path(contact_point)
      @refresh_url = contact_point_refresh_path(contact_point) unless params[:without_refresh]
    end
  end

  #callback for twilio
  def create
    @contact_point = ContactPoint.find_by(confirmation_token: params['CallSid'])
    @contact_point.verify!(status: params['VerificationStatus'], outgoing_sid: params['OutgoingCallerIdSid'])
    head :ok, content_type: 'text/html'
  end

  def destroy
    contact_point = fetch_contact_point
    VoiceSender.terminate_call(contact_point.call_sid)
    respond_to do |format|
      format.html { redirect_to contact_points_path }
      format.js   {}
    end
  end

  def show_modal
    @voice = fetch_contact_point
  end

  private

  def fetch_contact_point
    current_user.contact_points.find(params[:contact_point_id])
  end
end