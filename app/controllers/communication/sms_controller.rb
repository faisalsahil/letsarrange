class Communication::SmsController < Communication::ApplicationController
  http_basic_authenticate_with name: ENV['TWILIO_HTTP_USER'], password: ENV['TWILIO_HTTP_PASSWORD']

  def inbound
    SmsMessage.create_inbound(params)
    js false
    head 200, content_type: 'text/html'
  end
end