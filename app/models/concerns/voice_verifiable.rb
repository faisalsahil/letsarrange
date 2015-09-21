module VoiceVerifiable
  extend ActiveSupport::Concern

  included do
    alias_attribute :call_sid, :confirmation_token
    after_destroy :revoke_outgoing_caller
  end

  def verify!(call_info)
    if call_info[:status] == 'success'
      self.outgoing_caller_sid = call_info[:outgoing_sid]
      mark_as_verified!
    else
      errors.add(:base, 'The code you entered was invalid')
    end
  end

  def send_verification
    VoiceSender.send_verification(self)
  end

  private

  def revoke_outgoing_caller
    VoiceSender.revoke_outgoing_caller(outgoing_caller_sid) if voice? && verified?
  end
end