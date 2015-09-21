class Communication::EmailController < Communication::ApplicationController
  http_basic_authenticate_with name: ENV['POSTMARK_HTTP_USER'], password: ENV['POSTMARK_HTTP_PASSWORD']

  def inbound
    EmailMessage.create_inbound(params) unless marked_as_spam
    js false
    head 200, content_type: 'text/html'
  end

  private

  def marked_as_spam
    params[:Headers].find { |header| header[:Name] == 'X-Spam-Status' }[:Value] == 'Yes'
  end
end