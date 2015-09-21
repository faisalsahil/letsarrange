require 'twilio-ruby'

class HumanizedSmsSender < SmsSender
  class << self
    def send_message(broadcast, to)
      from = broadcast.request.reserved_number
      super(broadcast, to, from)
    end

    private

    def send_initial(broadcast, to, from)
      send_broadcast(broadcast, to, from, initial_body(broadcast))
    end

    def send_update(broadcast, to, from)
      send_broadcast(broadcast, to, from, update_body(broadcast))
    end

    def send_broadcast(broadcast, to, from, body)
      sms = broadcast.sms_messages.create!(to: to.number, from: from.number, body: body)
      delay.deliver_sms_message(sms.id)
    end

    def initial_body(broadcast)
      "Hi, this is #{ broadcast.author_name }. #{ broadcast.to_humanized_sentence }"
    end

    def update_body(broadcast)
      broadcast.body
    end
  end
end