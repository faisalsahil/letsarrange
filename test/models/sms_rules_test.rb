require 'test_helper'

class SmsRulesTest < ActiveSupport::TestCase
  def setup
    super
    @user = create_user(sms_sent_to_user_state: SmsSentToUserState::NEVER)

    User.stubs(:find_user).returns([@user])
    @user.contact_points.create!(type: 'ContactPoint::Sms', description: '10123456789')
    @sms_rules = SmsRules.new(@user.contact_points.first, TwilioNumber.first.number)
  end

  test 'it should respond to next_state!' do
    assert_respond_to @sms_rules, :next_state!
  end

  test 'next_state should move from NEVER to SIMULTANEOUS' do
    @user.sms_sent_to_user_state = SmsSentToUserState::NEVER
    @sms_rules.stubs(:user).returns(@user)

    @sms_rules.next_state!
    assert_equal SmsSentToUserState::SIMULTANEOUS, @user.sms_sent_to_user_state
  end

  test 'next_state should move from ONCE to SIMULTANEOUS' do
    @user.sms_sent_to_user_state =  SmsSentToUserState::ONCE
    @sms_rules.stubs(:user).returns(@user)

    @sms_rules.next_state!
    assert_equal SmsSentToUserState::SIMULTANEOUS, @user.sms_sent_to_user_state
  end

  test 'it should respond to send_code_instructions?'  do
    assert_respond_to @sms_rules, :send_code_instructions?
  end

  test 'send_code_instructions? should be false if SmsSentToUserState is SIMULTANEOUS' do
    @user.sms_sent_to_user_state =  SmsSentToUserState::SIMULTANEOUS
    @user.stubs(:needs_code?).returns(true)
    @sms_rules.stubs(:user).returns(@user)

    assert !@sms_rules.send_code_instructions?
  end

  test 'send_code_instructions? should be false if the user does not need code' do
    @user.sms_sent_to_user_state =  SmsSentToUserState::NEVER
    @sms_rules.stubs(:user).returns(@user)

    @user.expects(:needs_code?).returns(false)
    assert !@sms_rules.send_code_instructions?
  end

  test 'send_code_instructions? should be true if SmsSentToUserState is not SIMULTANEOUS and the user needs code' do
    @user.sms_sent_to_user_state =  SmsSentToUserState::ONCE
    @sms_rules.stubs(:user).returns(@user)
    @sms_rules.stubs(:from).returns(TwilioNumber.default_number.number)
    @user.stubs(:needs_code?).returns(true)

    assert @sms_rules.send_code_instructions?
  end
end