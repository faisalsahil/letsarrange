module VoiceBroadcastSender
  extend TwilioUrlHelper

  ACCEPTED_MESSAGE = '<Response><Say voice="alice">The appointment has been accepted. Thanks, Goodbye.</Say></Response>'
  DECLINED_MESSAGE = '<Response><Say voice="alice">The appointment has been declined. Thanks, Goodbye.</Say></Response>'
  MAX_INPUT_TRIES_ACTIONS = 2
  MAX_INPUT_TRIES_ANNOUNCEMENT = 2
  MAX_ANNOUNCE_REPEAT_TIMES = 5

  class << self
    def send_message(broadcast, to)
      return unless broadcast.systemized_messages? && broadcast.opening_broadcast? && broadcast.to_requested?
      from = to.user.mapping_for_entity(broadcast.line_item).twilio_number
      tts_broadcast = TextToSpeech.convert_broadcast(broadcast)
      TwilioApi.client.account.calls.create(url: announce_communication_voice_broadcast_url(broadcast: tts_broadcast, contact_point: { id: to.id }), to: to.number, from: from.number, ifMachine: 'Continue')
    end

    def list_actions(params, try: 1, times_repeated: 1, say_announcement: false)
      Twilio::TwiML::Response.new do |res|
        res.Say(params[:broadcast][:body], voice: 'alice') if say_announcement
        (try..MAX_INPUT_TRIES_ACTIONS).each do |try_to_post|
          res.Gather(timeout: 10, numDigits: 1, action: opening_call_actions_communication_voice_broadcast_url(params.merge(try: try_to_post, times_repeated: times_repeated))) do
            res.Say('To accept this appointment, press 1.', voice: 'alice')
            res.Say('To decline, press 2.', voice: 'alice')
            res.Say('To be connected to this person by phone, press 3', voice: 'alice')
            res.Say('To hear the appointment again, press 4.', voice: 'alice') if can_repeat_announcement?(times_repeated)
            manage_your_appointments(res, params[:contact_point][:id])
          end
        end
        closing_message(res, params[:contact_point][:id])
      end.text
    end

    def announce(params, try = 1)
      Twilio::TwiML::Response.new do |res|
        (try..MAX_INPUT_TRIES_ANNOUNCEMENT).each do |try_to_post|
          res.Say(params[:broadcast][:opening], voice: 'alice')
          res.Say(params[:broadcast][:header], voice: 'alice')
          res.Gather(timeout: 10, numDigits: 1, action: opening_call_communication_voice_broadcast_url(params.merge(try: try_to_post))) do
            res.Say('Please press 1 to hear this request', voice: 'alice')
          end
        end
        closing_message(res, params[:contact_point][:id])
      end.text
    end

    def announce_for_machine(params)
      line_item = Broadcast.find(params[:broadcast][:id]).line_item
      receiver_mapping = line_item.receiver.mapping_for_entity(line_item)

      Twilio::TwiML::Response.new do |res|
        res.Say(params[:broadcast][:opening], voice: 'alice')
        res.Say(params[:broadcast][:body], voice: 'alice')
        res.Say("To be connected to this person, please call this number, #{ receiver_mapping.number_and_code(tts: true) }", voice: 'alice')
        manage_your_appointments(res, params[:contact_point][:id])
        res.Say('Thank you, goodbye', voice: 'alice')
      end.text
    end

    def bridge_call(params)
      receiver_contact = ContactPoint.find(params[:contact_point][:id])
      line_item = Broadcast.find(params[:broadcast][:id]).line_item
      VoiceSender.dial_mapping(receiver_contact.user.mapping_for_entity(line_item), receiver_contact.number)
    end

    def can_repeat_announcement?(times_repeated)
      times_repeated < MAX_ANNOUNCE_REPEAT_TIMES
    end

    private

    def manage_your_appointments(builder, contact_point_id)
      builder.Say("To manage all your appointments and notifications, please go to lets arrange dot com, and enter your phone number, #{ TextToSpeech.number_with_breaks(ContactPoint.find(contact_point_id).denormalized) }.", voice: 'alice')
    end

    def closing_message(builder, contact_point_id)
      builder.Say("Sorry, but we didn't hear a response", voice: 'alice')
      manage_your_appointments(builder, contact_point_id)
      builder.Say('Thank you, goodbye', voice: 'alice')
    end
  end
end