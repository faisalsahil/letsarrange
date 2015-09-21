require 'twilio-ruby'

class SmsSender
  DEFAULT_DELAY_BETWEEN_MESSAGES = 2.seconds

  class << self
    # 'to' is a ContactPoint
    def send_message(broadcast, to, from)
      ActiveRecord::Base.transaction do
        broadcast.opening_broadcast? ? send_initial(broadcast, to, from) : send_update(broadcast, to, from)
      end
    end

    def send_password_reset(to, token)
      mapping = UrlMapping.static_mapping(:edit_user_password, reset_password_token: token)
      send_isolated_sms(to, TwilioNumber.default_number, password_reset_body(mapping))
    end

    def send_isolated_sms(to, from, body)
      delay.deliver_sms(to.number, from.number, body)
    end

    def deliver_sms(to, from, body)
      split_and_send(SmsMessage.new(to: to, from: from, body: body))
    rescue Twilio::REST::RequestError => e
      puts e.message
    end

    def deliver_sms_message(message_id)
      SmsMessage.find(message_id).tap do |message|
        tw_message = split_and_send(message)
        message.update_from(tw_message)
      end
    rescue Twilio::REST::RequestError => e
      puts e.message
    end

    def send_exception_message(exception, to, from)
      delay.deliver_sms(to, from, exception.to_sms)
    end

    def send_verification(contact_point)
      mapping = UrlMapping.create_for(contact_point)
      sms_body = "Your lets arrange verification code is #{ contact_point.confirmation_token }, or you can go to #{ mapping.to_url }"
      send_isolated_sms(contact_point, TwilioNumber.default_number, sms_body)
    end

    private

    def password_reset_body(url_mapping)
      "Someone has requested a link to change your letsarrange.com password. You can do this through #{ url_mapping.to_short_url }"
    end

    def split_and_send(message)
      delay_sms(message.to)

      remaining_message = message.body.strip
      loop do
        body = body_chunk(remaining_message)
        sms_message = TwilioApi.client.account.sms.messages.create(body: body,
                                                     to: "+#{ message.to }",
                                                     from: "+#{ message.from }")
        remaining_message = remaining_message[body.length..-1]
        break sms_message unless remaining_message.present?
        sleep(delay_between_sms)
      end
    end

    def delay_between_sms
      (ENV['DELAY_BETWEEN_SMS'] || DEFAULT_DELAY_BETWEEN_MESSAGES).to_i
    end

    def delay_sms(to_number)
      contact_point = ContactPoint::Sms.find_phone(to_number)
      contact_point.delay_sending_sms(delay_between_sms) if contact_point
    end

    def body_chunk(message)
      chunk = message[0..SmsMessage::MAX_LENGTH]
      chunk.sub!(/(\S)\s\S*\z/, '\1') if message && /\S/ =~ message[chunk.length]
      chunk
    end
  end
end