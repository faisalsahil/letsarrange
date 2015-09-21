class InvalidCodeException < StandardError
  def initialize(mappings)
    @mappings = mappings
  end

  def to_sms
    SmsCodesList.to_sms(@mappings)
  end
end

class InvalidLineItemException < StandardError
end

class NoRouteFoundException < StandardError
  def to_sms
    "We got your text, but we don't know what to do with it. Don't worry - go to #{ mapping.to_short_url } for more. Thanks!"
  end

  def to_mail
    "We got your email, but we don't know what to do with it. Don't worry - go to #{ mapping.to_short_url } for more. Thanks!"
  end

  private

  def mapping
    UrlMapping.active.where(path: Rails.application.routes.url_helpers.new_user_session_path).first_or_create!
  end
end

class AccessDeniedError < StandardError
  def message
    "You don't have the rights to access this page"
  end
end

module Twilio
  class UnknownFromError < StandardError
  end

  class UnverifiedFromError < StandardError
  end

  class NoMappingsError < StandardError
  end

  class AnonymousFromError < StandardError
  end

  class NoReceiverError < StandardError
  end
end