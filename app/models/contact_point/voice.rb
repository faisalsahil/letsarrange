class ContactPoint::Voice < ContactPoint
  include ContactPoint::Phone
  include VoiceVerifiable

  has_one :user_to_reset, foreign_key: :voice_reset_contact_id, class_name: :User

  after_save :check_preferred, unless: :notifiable?

  def humanized_type
    'Voice'
  end

  def short_type
    'voice'
  end

  def can_clone_to_sms?
    !ContactPoint::Sms.where(description: normalized_number).exists?
  end

  def send_password_reset(token)
    user.setup_for_reset_via_voice(self)
    token
  end

  def able_to_reset?
    verified? && user_to_reset.present? && user_to_reset.voice_reset_active?
  end

  def after_verification_sent(call_attrs)
    update!(confirmation_token: call_attrs.call_sid, confirmation_sent_at: Time.now.utc)
    call_attrs.validation_code
  end

  def enable_notifications
    previous = user.preferred_voice
    super.tap { |success| previous.try(:disable_notifications) if success }
  end

  def notification_captions(action)
    { disable: 'remove as active', enable: 'set as active' }[action]
  end

  def humanized_status(opts = {})
    return 'active' if notifiable?
    super
  end

  private

  def check_preferred
    if notifiable_was?
      user.ensure_preferred_voice(id)
    elsif verified?
      enable_notifications unless user.preferred_voice
    end
  end

  def set_default_notifications
    self.notifications_enabled = false if notifications_enabled.nil?
    true
  end

  def self._to_partial_path
    'contact_points/voice'
  end
end