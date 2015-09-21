class VoiceSender
  extend TwilioUrlHelper

  CALL_DELAY = 6
  CALL_MAX_DURATION = 5.minutes
  ANONYMOUS_NUMBERS = ['', '266696687', '7378742833', '2562533', '8656696']
  EMPTY_TWIML = '<Response></Response>'
  MAX_INPUT_TRIES = 3
  CONFERENCE_DEFAULT_OPTIONS = {
    startConferenceOnEnter: true,
    endConferenceOnExit: true,
    beep: false,
    waitUrl: ''
  }

  class << self
    def send_verification(contact_point)
      unverify_outgoing_caller(contact_point.number)
      call_attr = TwilioApi.client.account.outgoing_caller_ids.create(phone_number: contact_point.number,
                                                                      call_delay: CALL_DELAY,
                                                                      status_callback: verification_callback(contact_point))
      contact_point.after_verification_sent(call_attr)
    end

    def terminate_call(call_sid)
      call = TwilioApi.client.account.calls.get(call_sid)
      call.update(status: 'completed') if call
    rescue Exception => e
      Rails.logger.info e
    end

    def revoke_outgoing_caller(caller_sid)
      caller_id = TwilioApi.client.account.outgoing_caller_ids.get(caller_sid)
      caller_id.delete if caller_id
    rescue Exception => e
      Rails.logger.info e
    end

    def route_call(twilio_number, from, try, code)
      if twilio_number.reserved?
        route_reserved(twilio_number, from)
      else
        fail Twilio::AnonymousFromError if anonymous_number?(from)
        contact_point = number_to_contact(from) or fail Twilio::UnknownFromError.new
        if contact_point.able_to_reset?
          route_to_password_reset(try)
        else
          route_to_orgs(contact_point, twilio_number, try, code)
        end
      end
    end

    def rescue_from(exception)
      message = case exception
                when Twilio::AnonymousFromError then 'Hi, this is letsarrange.com. We cannot verify the phone number you are calling from. Please unblock your caller id by dialing star 82 first. Thanks'
                when Twilio::UnknownFromError then 'Hi, this is letsarrange.com. We cannot verify the phone number you are calling from. Please call back from a number on your account. Thanks'
                when Twilio::UnverifiedFromError then "Hi, this is letsarrange.com. Your phone number hasn't been verified. Please verify it first via the application"
                when Twilio::NoMappingsError then "Hi, this is letsarrange.com. The call couldn't be routed. Make sure you are calling the correct phone number"
                when Twilio::NoReceiverError then 'Hi, this is letsarrange.com. We cannot connect your call as the other party does not have a number that is enabled for voice. Please send messages through Text or through the website. Thanks'
                else
                  puts exception, exception.backtrace
                  'An error occurred'
                end
      say(message)
    end

    def route_to_password_reset(try)
      Twilio::TwiML::Response.new do |res|
        res.Say('Wrong validation code', voice: 'alice') unless try == 1
        (try..MAX_INPUT_TRIES).each do |try_to_post|
          res.Gather(timeout: 10, action: communication_voice_reset_password_url(try: try_to_post)) do
            res.Say 'To finish the password reset process, please enter the code shown in the website followed by pound', voice: 'alice'
          end
        end
      end.text
    end

    def after_password_reset
      Twilio::TwiML::Response.new do |res|
        res.Say('Your identity has been verified. You can now continue with the password reset process via the website', voice: 'alice')
      end.text
    end

    def number_to_contact(number)
      ContactPoint.phone.enabled.find_phone(number)
    end

    def anonymous_number?(number)
      ANONYMOUS_NUMBERS.include?(number)
    end

    def cancel_call(sid)
      call = TwilioApi.client.account.calls.get(sid)
      call.update(status: 'completed')
      EMPTY_TWIML
    end

    def dial_mapping(mapping, from)
      bridge_to_number = mapping.voice_number
      caller_info = mapping.caller_info
      conference_id = "org-bridge-#{ from }"
      called_announcement = calling_announcement(caller_info.organization_user, caller_info.organization_resource) if caller_info.organization_user.present?
      caller_announcement = "Calling #{ TextToSpeech.convert(mapping.resource_full_name) }"

      start_conference(conference_id, bridge_to_number, caller_info.caller_id, called_announcement: called_announcement, caller_announcement: caller_announcement)
    end

    private

    def route_to_orgs(from_contact, twilio_number, try, code)
      mappings = matching_mappings(from_contact.user, twilio_number)
      mapping = mappings.find { |m| m.code == code } if code
      if mapping
        dial_mapping(mapping, from_contact.number)
      else
        mappings.count == 1 ? dial_mapping(mappings.first, from_contact.number) : list_options(mappings, try)
      end
    end

    def route_reserved(twilio_number, from)
      bridge_to_number = twilio_number.request.voice_number
      caller_id = twilio_number.caller_id_for_number(from)
      conference_id = "reserved-bridge-#{ from }"
      announcement = announcement(from, twilio_number.request)

      start_conference(conference_id, bridge_to_number, caller_id, called_announcement: announcement)
    end

    def wait_url
      @wait_url ||= (
        file_url = "http:#{ ActionController::Base.asset_host || "//#{ ENV['HOST_URL'] }"}#{ ActionController::Base.helpers.asset_path('phone_calling.mp3') }"
        play_twiml = Twilio::TwiML::Response.new { |res| res.Play file_url, loop: 0 }.text
        "http://twimlets.com/echo?#{ { Twiml: play_twiml }.to_query }"
      )
    end

    def beep_url
      "http:#{ ActionController::Base.asset_host || "//#{ ENV['HOST_URL'] }"}#{ ActionController::Base.helpers.asset_path('beep.wav') }"
    end

    def unverify_outgoing_caller(number)
      TwilioApi.client.account.outgoing_caller_ids.list(phone_number: number).each(&:delete)
    end

    def matching_mappings(user, twilio_number)
      #exclude mappings without a voice_number to route to
      user.matching_mappings(twilio_number).select(&:voice_number).presence or fail Twilio::NoMappingsError.new
    end

    def list_options(mappings, try)
      Twilio::TwiML::Response.new do |res|
        res.Say("We didn't recognize that code", voice: 'alice') unless try == 1
        #avoids one <Gather> with <Redirect> to minimize hits to our backend
        (try..MAX_INPUT_TRIES).each { |try_to_post| mappings_menu(res, mappings, try_to_post) }

        res.Say 'Sorry you are having trouble. Please try again later. Goodbye.', voice: 'alice'
      end.text
    end

    def mappings_menu(res, mappings, try)
      res.Gather(timeout: 10, action: communication_voice_inbound_url(try: try)) do
        res.Say 'There are more than one organization available to call. Please enter the corresponding code followed by pound', voice: 'alice'
        mappings.each { |m| res.Say "For #{ m.resource_full_name }, enter #{ m.code } then pound", voice: 'alice' }
      end
    end

    def say(message)
      Twilio::TwiML::Response.new { |r| r.Say "#{ message }. Goodbye.", voice: 'alice' }.text
    end

    def verification_callback(contact_point)
      contact_point_voice_verification_url(contact_point)
    end

    def start_conference(conference_id, attendant_number, caller_id, caller_announcement: nil, called_announcement: nil)
      fail Twilio::NoReceiverError.new unless attendant_number

      conference_id = "#{ conference_id }-#{ Time.now.to_i.to_s }"
      call_sid = call_conference_participant(conference_id, attendant_number, caller_id, called_announcement).sid
      join_conference(conference_id, announcement: caller_announcement, startConferenceOnEnter: false, waitMethod: 'get', waitUrl: wait_url, dependant_sid: call_sid)
    end

    def call_conference_participant(conference_id, attendant_number, caller_id, announcement)
      response = join_conference(conference_id, announcement: announcement, on_enter_beep: announcement.present?)
      TwilioApi.client.account.calls.create(url: "http://twimlets.com/echo?#{ { Twiml: response }.to_query }", to: attendant_number, from: caller_id)
    end

    def join_conference(conference_id, opts = {})
      announcement = opts.delete(:announcement).presence
      dependant_sid = opts.delete(:dependant_sid).presence
      dial_opts = { timeLimit: CALL_MAX_DURATION }
      dial_opts.merge!(action: communication_voice_cancel_call_url(sid_to_cancel: dependant_sid)) if dependant_sid
      Twilio::TwiML::Response.new do |res|
        res.Say(announcement, voice: 'alice') if announcement
        res.Play(beep_url) if opts.delete(:on_enter_beep)
        res.Dial(dial_opts)  do
          res.Conference conference_id, CONFERENCE_DEFAULT_OPTIONS.merge(opts)
        end
      end.text
    end

    def announcement(from, request)
      if anonymous_number?(from)
        "Unknown caller calling about #{ resource_announcement(request.organization_resource) }"
      else
        caller = OrganizationUser.joins(user: :contact_points).where(contact_points: { description: from }, organization_id: request.requested_organizations).merge(ContactPoint.voice).first
        if caller
          calling_announcement(caller, request.organization_resource)
        else
          denormalized_from = ContactPoint::Phone.denormalized(from).gsub(/\D/, '')
          calling_announcement(denormalized_from, request.organization_resource)
        end
      end
    end

    def calling_announcement(caller, organization_resource = nil)
      caller_announcement = "#{ caller_announcement(caller) } calling"
      if organization_resource
        "#{ caller_announcement } about #{ resource_announcement(organization_resource, skip_organization: caller.is_a?(OrganizationUser) && organization_resource.organization == caller.organization) }"
      else
        caller_announcement
      end
    end

    def caller_announcement(caller)
      TextToSpeech.convert(caller.is_a?(OrganizationUser) ? caller.full_name : caller)
    end

    def resource_announcement(organization_resource, skip_organization: false)
      TextToSpeech.convert(skip_organization ? organization_resource.name : organization_resource.full_name)
    end
  end
end