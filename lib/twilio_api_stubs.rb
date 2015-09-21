module TwilioApiStubs
  extend ActiveSupport::Concern

  included do
    remove_method :client
    remove_method :buy_number
    remove_method :incoming_numbers
  end

  def client
    @twilio_client ||= Twilio::REST::Client.new ENV['TWILIO_TEST_SID'], ENV['TWILIO_TEST_AUTH_TOKEN']
  end

  def buy_number(area_code)
    area_code ||= default_area_code
    begin
      number = "1#{ area_code }#{ rand(1_000_0000).to_s.rjust(7, '0') }"
    end while TwilioNumber.unscoped.find_by(number: number)
    number
  end

  def incoming_numbers
    Rails.env.test? ? [ENV['TWILIO_TEST_PHONE_NUMBER']] : [ENV['TWILIO_DEV_PHONE_NUMBER'], ENV['TWILIO_DEV_PHONE_NUMBER_2']]
  end
end