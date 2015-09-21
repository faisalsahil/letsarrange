class SmsRules
  attr_reader :user, :from

  def initialize(to, from)
    @user = to.user
    @from = from
  end

  def send_code_instructions?
    user.sms_sent_to_user_state != SmsSentToUserState::SIMULTANEOUS && user.needs_code?(from)
  end

  def next_state!
    user.update_column(:sms_sent_to_user_state, SmsSentToUserState::SIMULTANEOUS)
  end
end