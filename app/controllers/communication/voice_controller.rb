class Communication::VoiceController < Communication::ApplicationController
  http_basic_authenticate_with name: ENV['TWILIO_HTTP_USER'], password: ENV['TWILIO_HTTP_PASSWORD']

  before_filter :normalize_params
  before_filter :deny_anonymous, only: :reset_password

  def inbound
    twiml_response = begin
      twilio_number = TwilioNumber.find_by(number: params[:To])
      VoiceSender.route_call(twilio_number, params[:From], params[:try], params[:Digits])
    rescue Exception => e
      VoiceSender.rescue_from(e)
    end
    render xml: twiml_response
  end

  def reset_password
    twiml_response = begin
      contact_point = VoiceSender.number_to_contact(params[:From]) or fail Twilio::UnknownFromError.new
      if contact_point.user.reset_password_via_voice(params[:Digits])
        VoiceSender.after_password_reset
      else
        VoiceSender.route_to_password_reset(params[:try])
      end
    rescue Exception => e
      VoiceSender.rescue_from(e)
    end
    render xml: twiml_response
  end

  def cancel_call
    render xml: VoiceSender.cancel_call(params[:sid_to_cancel])
  end

  private

  def deny_anonymous
    fail Twilio::AnonymousFromError if VoiceSender.anonymous_number?(params[:From])
  end

  def normalize_params
    params[:try] = params[:try].to_i + 1 if params[:try]
    params[:From] = params[:From].delete('+') if params[:From]
    params[:To] = params[:To].delete('+') if params[:To]
  end
end