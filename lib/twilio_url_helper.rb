module TwilioUrlHelper
  include Rails.application.routes.url_helpers

  def default_url_options
    { host: ENV['HOST_URL'], protocol: 'https', user: ENV['TWILIO_HTTP_USER'], password: ENV['TWILIO_HTTP_PASSWORD'] }
  end
end