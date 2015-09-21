class PhoneMapping < Mapping
  belongs_to :twilio_number, foreign_key: :endpoint_id

  validates :twilio_number, presence: true
  validates :endpoint_id, uniqueness: { scope: [:user_id, :entity_id, :entity_type, :status] }

  def same_contact_mappings
    user.phone_mappings.active.where(twilio_number: twilio_number)
  end

  def needs_code?
    same_contact_mappings.count != 1
  end

  def attach_to(body)
    needs_code? ? "#{ code }: #{ body }" : body
  end

  def voice_number
    entity.voice_number(user)
  end

  def caller_info
    entity.caller_info(user)
  end

  def resource_name
    entity.resource_name(user)
  end

  def resource_full_name
    entity.resource_full_name(user)
  end

  def number_and_code(tts: false)
    caption = ContactPoint::Phone.denormalized(twilio_number.number)
    caption = TextToSpeech.number_with_breaks(caption) if tts
    caption << " and use code " << (tts ? TextToSpeech.convert(code) : code) if needs_code?
    caption
  end

  private

  def generate_code
    PhoneMapping.unscoped do
      max_code = same_contact_mappings.order('code::int desc').first.try(:code) || 0
      self.code = (max_code.to_i + 1).to_s
    end
  end

  def self.create_for(user, entity, twilio_number = nil)
    twilio_number ||= TwilioNumber.number_for_user(user, entity)
    user.phone_mappings.active.for_entity(entity).where(twilio_number: twilio_number).first_or_create!
  end

  def self.parse_code(body)
    code = body.split(" ").first
    return nil unless (code =~ /^[0-9]+$/)
    code
  end

  def self.strip_code(body)
    code, stripped_body = body.split(' ', 2)
    code =~ /^[0-9]+$/ ? stripped_body : body
  end

  def self.for_twilio(twilio_number)
    if twilio_number.is_a?(TwilioNumber)
      where(twilio_number: twilio_number)
    else
      joins(:twilio_number).where(twilio_numbers: { number: twilio_number })
    end
  end
end