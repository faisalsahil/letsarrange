module TwilioApi
  class << self
    include Rails.application.routes.url_helpers

    def client
      @twilio_client ||= Twilio::REST::Client.new ENV['TWILIO_SID'], ENV['TWILIO_AUTH_TOKEN']
    end

    def buy_with_area(area_code)
      client.account.incoming_phone_numbers.create(area_code: area_code)
    end

    def default_area_code
      '500'
    end

    def buy_number(area_code)
      area_code ||= default_area_code
      begin
        number = buy_with_area(area_code)
      rescue Twilio::REST::RequestError => e
        number = buy_with_area(default_area_code) if e.to_s == 'No phone numbers found' && area_code != default_area_code
      end
      url_prefix = "https://#{ ENV['TWILIO_HTTP_USER'] }:#{ ENV['TWILIO_HTTP_PASSWORD'] }@#{ ENV['HOST_URL'] }"
      number.update(friendly_name: ENV['APP_NAME'], voice_url: "#{ url_prefix }#{ communication_voice_inbound_path }", sms_url: "#{ url_prefix }#{ communication_sms_inbound_path }")
      number.phone_number
    end

    def incoming_numbers
      if ENV['APP_NAME'] && TwilioNumber.table_exists? #TODO: defer the loading until needed to avoid this ugly hacky fix for rake tasks
        client.account.incoming_phone_numbers.list(friendly_name: ENV['APP_NAME']).map do |number|
          number.phone_number.delete('+')
        end
      else
        []
      end
    end

    include(TwilioApiStubs) unless Rails.env.production?
  end
end