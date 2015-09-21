module MailerSettings
  SETTINGS = {
      ENV['MAIL_DOMAIN'] => {
          port: '25',
          address: ENV['POSTMARK_SMTP_SERVER'],
          user_name: ENV['POSTMARK_API_KEY'],
          password: ENV['POSTMARK_API_KEY'],
          domain: ENV['HOST_URL'],
          authentication: :plain,
      },
      ENV['MAILNET_DOMAIN'] => {
          port: '25',
          address: ENV['POSTMARK_SMTP_SERVER'],
          user_name: ENV['POSTMARK_API_KEY_MAILNET'],
          password: ENV['POSTMARK_API_KEY_MAILNET'],
          domain: ENV['MAILNET_DOMAIN'],
          authentication: :plain,
      }
  }

  def self.[](domain)
    SETTINGS[domain]
  end
end