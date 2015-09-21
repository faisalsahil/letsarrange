require 'twilio-ruby'

class SystemizedSmsSender < SmsSender
  class << self
    def send_message(broadcast, to)
      from = to.user.mapping_for_entity(broadcast.line_item).twilio_number
      super(broadcast, to, from)
    end

    private

    def send_initial(broadcast, to, from)
      send_opening_and_body(broadcast, to, from)
      send_isolated_sms(to, from, initial_closing(broadcast, to))
      send_code_instructions(to, from)
    end

    def send_update(broadcast, to, from)
      sms_body = update_body(broadcast, to)
      sms = broadcast.sms_messages.create!(to: to.number, from: from.number, body: sms_body)
      delay.deliver_sms_message(sms.id)

      send_code_instructions(to, from)
    end

    def send_code_instructions(to, from)
      rules = SmsRules.new(to, from)
      if rules.send_code_instructions?
        mappings = to.user.matching_mappings(from)
        send_isolated_sms(to, from, SmsCodesList.to_sms(mappings))
        rules.next_state!
      end
    end

    def initial_opening(broadcast)
      "#{ broadcast.author_name }#{ broadcast.author_rep } has sent you an appointment request via letsarrange.com:"
    end

    def initial_closing(broadcast, to)
      url_mapping = UrlMapping.create_for(to, broadcast.line_item)
      phone_mapping = to.user.mapping_for_entity(broadcast.line_item)
      "To accept, counter-offer, or decline, go to #{ url_mapping.to_url }. Or, simply reply to this text or call this number#{ " (using code #{ phone_mapping.code })" if phone_mapping.needs_code? } to reach this person"
    end

    def initial_body(broadcast)
      broadcast.body
    end

    def update_body(broadcast, to)
      sms_body = broadcast.full_body
      sms_body = to.user.mapping_for_entity(broadcast.line_item).attach_to(sms_body)
      UrlMapping.create_for(to, broadcast.line_item).attach_to(sms_body)
    end

    def send_opening_and_body(broadcast, to, from)
      opening = initial_opening(broadcast)
      broadcast_body = initial_body(broadcast)
      unified_opening = "#{ opening } #{ broadcast_body }"
      main_body = if unified_opening.length <= SmsMessage::MAX_LENGTH
                    unified_opening
                  else
                    send_isolated_sms(to, from, opening)
                    broadcast_body
                  end
      sms = broadcast.sms_messages.create!(to: to.number, from: from.number, body: main_body)
      delay.deliver_sms_message(sms.id)
    end
  end
end