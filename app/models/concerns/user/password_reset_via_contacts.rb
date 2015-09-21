module User::PasswordResetViaContacts
  VOICE_RESET_TOKEN_DURATION = 15.minutes

  extend ActiveSupport::Concern

  included do
    belongs_to :voice_reset_contact, class_name: 'ContactPoint::Voice'
    attr_accessor :password_reset_contact
  end

  def send_reset_password_instructions(cp_attrs)
    cp_attrs[:description] = ContactPoint::Phone.normalize(cp_attrs[:description]) unless cp_attrs[:type] == 'email'
    cp_attrs[:type] = ContactPoint.full_type(cp_attrs[:type])
    self.password_reset_contact = contact_points.verified.find_by!(cp_attrs)

    clear_voice_reset
    token = super()

    self.password_reset_contact = nil
    token
  end

  def setup_for_reset_via_voice(voice_contact)
    self.voice_reset_contact = voice_contact
    self.voice_reset_code = generate_voice_code
    save(validate: false)
  end

  def reset_password_via_voice(code)
    if code == voice_reset_code
      clear_voice_reset
      save(validate: false)
    end
  end

  def voice_reset_in_progress?
    voice_reset_code.present?
  end

  def voice_reset_active?
    reset_password_sent_at > VOICE_RESET_TOKEN_DURATION.ago
  end

  private

  def clear_voice_reset
    self.voice_reset_code = nil
    self.voice_reset_contact = nil
  end

  def generate_voice_code
    (100_000 + SecureRandom.random_number(900_000)).to_s
  end

  def send_devise_notification(notification, token, opts = {})
    notification == :reset_password_instructions ? password_reset_contact.send_password_reset(token) : super
  end

  module ClassMethods
    def send_reset_password_instructions(attrs = {})
      user = find_by!(uniqueid: clean(attrs[:uniqueid]))
      user.send_reset_password_instructions(attrs[:contact_point_for_reset])
    rescue ActiveRecord::RecordNotFound
      fake_token
    end

    def find_by_encrypted_token(token)
      find_by(reset_password_token: Devise.token_generator.digest(User, :reset_password_token, token))
    end

    def fake_token
      Devise.friendly_token[0..-2]
    end

    def fake_token?(token)
      token.length != Devise.friendly_token.length
    end

    def fake_code(token)
      (100_000 + token.each_char.each_with_index.reduce(0) { |sum, (char, index)| sum + char.ord * index * 3}).to_s
    end
  end
end