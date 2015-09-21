module SmsVerifiable
  extend ActiveSupport::Concern

  SMS_VERIFICATION_CODE_LENGTH = 6

  included do
    after_create :send_verification, if: :unverified?
  end

  def verify!(code)
    verify_sms_code(code)
  end

  def send_verification
    generate_sms_verification_code
    SmsSender.send_verification(self)
  end

  private

  def generate_sms_verification_code
    self.confirmation_sent_at = Time.now.utc
    self.confirmation_token = SecureRandom.random_number(10 ** SMS_VERIFICATION_CODE_LENGTH).to_s.rjust(SMS_VERIFICATION_CODE_LENGTH, '0') unless has_sms_verification_code?
    save and confirmation_token
  end

  def has_sms_verification_code?
    confirmation_token && confirmation_token.length == SMS_VERIFICATION_CODE_LENGTH
  end

  def verify_sms_code(code)
    if code == confirmation_token
      if confirmation_sent_at < 2.days.ago
        errors.add(:base, 'The code has expired, please request a new one')
      else
        mark_as_verified!
      end
    else
      errors.add(:base, 'The verification code is invalid')
    end
  end
end