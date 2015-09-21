class ContactPoint::Sms < ContactPoint
  include ContactPoint::Phone
  include SmsVerifiable

  def humanized_type
    'SMS'
  end

  def short_type
    'sms'
  end

  def can_clone_to_voice?
    !ContactPoint::Voice.where(description: normalized_number).exists?
  end

  def sms_sent_and_received
    SmsMessage.with_number(number)
  end

  def send_password_reset(token)
    SmsSender.send_password_reset(self, token)
  end

  def able_to_reset?
    false
  end

  def delay_sending_sms(delay)
    if must_wait_to_send_sms?(delay)
      sleep_seconds = delay - (Time.now - last_sms_sent_at)
      update_column(:last_sms_sent_at, Time.now + sleep_seconds)
      sleep(sleep_seconds)
    else
      update_column(:last_sms_sent_at, Time.now)
    end
  end

  private

  def must_wait_to_send_sms?(delay)
    last_sms_sent_at && last_sms_sent_at + delay > Time.now
  end

  def self._to_partial_path
    'contact_points/sms'
  end
end