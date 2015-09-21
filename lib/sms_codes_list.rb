module SmsCodesList
  def self.to_sms(mappings)
    opening = 'Begin replies with '
    requests_mapping = UrlMapping.active.where(path: Rails.application.routes.url_helpers.received_line_items_path).first_or_create!
    ending = ". Or go to #{ requests_mapping.to_short_url }"

    codes = mappings.map { |m| "#{ m.code } (#{ m.resource_name })" }
    codes_list = codes.to_sentence(two_words_connector: ' or ', last_word_connector: ', or ')
    msg = "#{ opening }#{ codes_list }#{ ending }"
    if msg.length > SmsMessage::MAX_LENGTH
      codes_length = SmsMessage::MAX_LENGTH - opening.length - ending.length - 4
      codes_list = "#{ codes_list[0..codes_length] }..."
      msg = "#{ opening }#{ codes_list }#{ ending }"
    end

    msg
  end
end