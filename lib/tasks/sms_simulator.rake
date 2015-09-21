namespace :sms_simulator do
  desc "send sms"
  task :send, [:from, :to] => :environment do |_, args|
    require 'rest_client'
    inbound_url = Rails.application.routes.url_helpers.communication_sms_inbound_url(host: ENV['HOST_URL'])
    from = args.from || PhoneMapping.first.user.contacts_sms.first.number
    to = args.to || TwilioNumber.default_number
    body = ENV['BODY'] || 'David says good morning'
    r = RestClient::Resource.new(inbound_url, ENV['TWILIO_HTTP_USER'], ENV['TWILIO_HTTP_PASSWORD'])
    r.post( { "AccountSid"=>"AC8244bade3dd5dd45e13ec70b9a7763eb",
              "MessageSid"=>"SMda6ae181970401ec3bd3cd2ceaeccd4b",
              "Body"=>body, "ToZip"=>"27536",
              "ToCity"=>"RALEIGH", "FromState"=>"CA", "ToState"=>"NC",
              "SmsSid"=>"SMda6ae181970401ec3bd3cd2ceaeccd4b", "To"=>"+#{ to }",
              "ToCountry"=>"US", "FromCountry"=>"US",
              "SmsMessageSid"=>"SMda6ae181970401ec3bd3cd2ceaeccd4b",
              "ApiVersion"=>"2010-04-01", "FromCity"=>"IGNACIO", "SmsStatus"=>"received",
              "NumMedia"=>"0", "From"=>"+#{ from }", "FromZip"=>"94949" })
  end
end