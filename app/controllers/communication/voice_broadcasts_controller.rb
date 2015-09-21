class Communication::VoiceBroadcastsController < Communication::ApplicationController
  http_basic_authenticate_with name: ENV['TWILIO_HTTP_USER'], password: ENV['TWILIO_HTTP_PASSWORD']

  before_filter :normalize_params

  def announce
    render xml: if params[:AnsweredBy] == 'machine'
                  VoiceBroadcastSender.announce_for_machine(broadcast_params)
                else
                  VoiceBroadcastSender.announce(broadcast_params)
                end
  end

  def opening_call
    response = if params[:Digits] == '1'
                 VoiceBroadcastSender.list_actions(broadcast_params, say_announcement: true)
               else
                 VoiceBroadcastSender.announce(broadcast_params, params[:try])
               end
    render xml: response
  end

  def opening_call_actions
    response = case params[:Digits]
                 when '1' then LineItem.accept_via_ivr(params[:broadcast][:id], params[:contact_point][:id])
                 when '2' then LineItem.close_via_ivr(params[:broadcast][:id], params[:contact_point][:id])
                 when '3' then VoiceBroadcastSender.bridge_call(broadcast_params)
                 else
                   if params[:Digits] == '4' && VoiceBroadcastSender.can_repeat_announcement?(params[:times_repeated])
                     VoiceBroadcastSender.list_actions(broadcast_params, try: params[:try] - 1, times_repeated: params[:times_repeated] + 1, say_announcement: true)
                   else
                     VoiceBroadcastSender.list_actions(broadcast_params, try: params[:try], times_repeated: params[:times_repeated])
                   end
               end
    render xml: response
  end

  private

  def broadcast_params
    params.slice(:broadcast, :contact_point)
  end

  def normalize_params
    params[:try] = params[:try].to_i + 1 if params[:try]
    params[:times_repeated] = params[:times_repeated].to_i if params[:times_repeated]
  end
end