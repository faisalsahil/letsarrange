class SmsMessage < ActiveRecord::Base
  MAX_LENGTH = 160

  validates_presence_of :to, :from, :body
  belongs_to :broadcast
  has_one :line_item, through: :broadcast

  scope :with_number, ->(number) { where('broadcast_id IS NOT NULL').where("#{ self.table_name }.from = ? OR #{ self.table_name }.to = ?", number, number) }

  def update_from(message)
    update(sid: message.sid, status: message.status, uri: message.uri)
  end

  def rebuild_broadcast
    to_number = TwilioNumber.find_by!(number: to)
    from_cp = ContactPoint::Sms.find_or_initialize_by(description: from)
    if to_number.reserved?
      build_broadcast_from_reserved(to_number, from_cp)
    else
      build_broadcast_from_mapping(to_number, from_cp.user)
    end
  end

  def contact_point
    ContactPoint.sms.find_by(description: to)
  end

  def to_user
    contact_point.try(:user)
  end

  def to_backend?
    TwilioNumber.where(number: to).exists?
  end

  private

  def fetch_mapping(twilio_number, author)
    fail NoRouteFoundException.new unless author
    mappings = author.matching_mappings(twilio_number).presence or fail NoRouteFoundException.new
    mappings.count == 1 ? mappings.first : find_mapping_by_code(mappings)
  end

  def find_mapping_by_code(mappings)
    code = PhoneMapping.parse_code(body)
    mapping = mappings.find_by(code: code) if code
    mapping or fail InvalidCodeException.new(mappings)
  end

  def build_broadcast_from_mapping(twilio_number, author)
    mapping = fetch_mapping(twilio_number, author)
    self.broadcast = Broadcast.create_with_user(broadcastable: mapping.entity, user: author, body: body_without_code(mapping.code))
  end

  def build_broadcast_from_reserved(twilio_number, contact_point)
    target_entity = twilio_number.request.receiver_for_reserved_message(contact_point)
    self.broadcast = Broadcast.create_with_user(broadcastable: target_entity, user: contact_point.user, body: body)
  end

  def body_without_code(code)
    body.sub(/\A#{ code }\s+/, '')
  end

  def self.new_inbound(raw_sms)
    new(sid: raw_sms['MessageSid'],
      to: raw_sms['To'],
      from: raw_sms['From'],
      body: raw_sms['Body'],
      status: raw_sms['SmsStatus'])
  end

  def self.create_inbound(raw_sms)
    raw_sms['From'].delete!('+')
    raw_sms['To'].delete!('+')
		begin
      transaction do
        sms = SmsMessage.new_inbound(raw_sms)
        sms.rebuild_broadcast
        sms.save
      end
    rescue NoRouteFoundException, InvalidCodeException => e
      SmsSender.send_exception_message(e, raw_sms['From'], raw_sms['To'])
    end
  end
end