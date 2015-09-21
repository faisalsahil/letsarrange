class EmailMessage < ActiveRecord::Base
  MAIL_DOMAINS = { systemized: ENV['MAIL_DOMAIN'], humanized: ENV['MAILNET_DOMAIN'] }
  MAX_EMAIL_REPLY_LENGTH = 160
  EMAIL_QUOTE_INDICATORS = [
    /^\d{4}\-\d{2}\-\d{2}.*>:$.*\z/m,
    /^Sent.*\z/m,
    /^____________.*\z/m
  ]

  with_options presence: true do |v|
    v.validates :to
    v.validates :from
    v.validates :body
    v.validates :subject
  end

  belongs_to :broadcast

  alias_attribute :sid, :uid

  scope :with_address, ->(address) { where('broadcast_id IS NOT NULL').where("#{ self.table_name }.from = ? OR #{ self.table_name }.to = ?", address, address) }

  def rebuild_broadcast
    mapping = fetch_mapping
    add_from_as_contact_of(mapping.user)
    self.broadcast = Broadcast.create_with_user(broadcastable: mapping.entity, user: mapping.user, body: email_to_broadcast_body)
  end

  def to_backend?
    uid.present?
  end

  def contact_point
    ContactPoint::Email.find_by(description: to)
  end

  def to_user
    contact_point.user
  end

  private

  def fetch_mapping
    EmailMapping.active.find_by(code: reply_code) or fail NoRouteFoundException.new
  end

  def reply_code
    base = to.split('@')[0]
    _, code = base.split('+')
    code
  end

  def email_to_broadcast_body
    body.gsub(/\s+/, ' ')[0...MAX_EMAIL_REPLY_LENGTH]
  end

  def add_from_as_contact_of(user)
    ContactPoint::Email.create(description: from, user: user, status: ContactPointState::UNVERIFIED)
  end

  def self.new_inbound(raw_mail)
    new(uid: raw_mail[:MessageID],
        to: backend_address(raw_mail[:ToFull]),
        from: raw_mail[:FromFull][:Email],
        body: body_without_quotes(raw_mail[:TextBody]),
        subject: raw_mail[:Subject])
  end

  def self.create_inbound(raw_mail)
    return if EmailMessage.find_by(uid: raw_mail[:MessageID])
    begin
      transaction do
        mail = new_inbound(raw_mail)
        mail.rebuild_broadcast
        mail.save
      end
    rescue NoRouteFoundException => e
      puts e.message
      #TODO: come up with an error handler that avoids replying to spam
      #EmailSender.send_exception_message(e, backend_address(raw_mail[:ToFull]), raw_mail[:FromFull][:Email])
    end
  end

  def self.backend_address(addresses)
    address = addresses.find { |address| MAIL_DOMAINS.values.include?(address[:Email].split('@').last) } or fail NoRouteFoundException.new
    address[:Email]
  end

  def self.body_without_quotes(body)
    visible_body = EmailReplyParser.parse_reply(body)
    EMAIL_QUOTE_INDICATORS.each { |indicator| visible_body.gsub!(indicator, '') }
    visible_body.strip
  end
end