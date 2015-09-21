class BroadcastMailer < ApplicationMailer
  def new_broadcast(message_id)
    email = EmailMessage.find(message_id)
    mail(to: email.to, from: email.from, subject: email.subject, body: email.body)
  end

  def error_message(from, to, message)
    mail(to: to, from: from, subject: 'An error occurred', body: message)
  end

  class DynamicSettingsInterceptor
    def self.delivering_email(message)
      settings = load_settings(message.from[0])
      message.delivery_method.settings.merge!(settings)
    end

    def self.load_settings(from_address)
      domain = from_address.split('@').last
      MailerSettings[domain]
    end
  end
  register_interceptor DynamicSettingsInterceptor
end
