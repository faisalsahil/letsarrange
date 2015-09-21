require 'mail'

module EmailSender
  class << self
    # 'to' is a ContactPoint
    def send_message(broadcast, to)
      mapping     = EmailMapping.mapping_for(to.user, broadcast.broadcastable)
      url_mapping = UrlMapping.create_for(to, broadcast.broadcastable)
      body        = mail_body(broadcast, url_mapping, broadcast.opening_broadcast?)
      message     = broadcast.email_messages.create!(to: to.email,
                                                     from: mail_from(broadcast, mapping),
                                                     body: body,
                                                     subject: subject(broadcast.author_name))
      BroadcastMailer.delay.new_broadcast(message.id)
    end

    def send_exception_message(exception, from, to)
      BroadcastMailer.delay.error_message(from, to, exception.to_mail)
    end

    def send_password_reset(to, token)
      PasswordMailer.delay.password_reset(to.id, token)
    end

    private

    def mail_body(broadcast, url_mapping, is_initial=false)
      if is_initial
        if broadcast.humanized_messages?
          <<-MAIL
Hi, this is #{ broadcast.author_name }.

#{ broadcast.to_humanized_sentence }
          MAIL
        else
          <<-MAIL
#{ broadcast.author_name }#{ broadcast.author_rep } has sent you an appointment request via letsarrange.com

#{ broadcast.body }

To accept, counter-offer, or decline, go to #{ url_mapping.to_url }. Or, simply reply to this email.
          MAIL
        end
      else
        if broadcast.humanized_sender?
          broadcast.body
        else
          <<-MAIL
New message via letsarrange.com

#{ DateHelper.created_at_for_broadcast(broadcast) }:

#{ broadcast.body }

Go to #{ url_mapping.to_url }, or reply by email.
          MAIL
        end
      end
    end

    def subject(sender)
      "Message from #{ sender }"
    end

    def mail_from(broadcast, email_mapping)
      address = Mail::Address.new(email_mapping.email_address(mail_domain(broadcast)))
      address.display_name = broadcast.author_name.dup
      address.format
    end

    def mail_domain(broadcast)
      EmailMessage::MAIL_DOMAINS[broadcast.humanized_sender? ? :humanized : :systemized]
    end
  end
end