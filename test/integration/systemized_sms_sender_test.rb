require 'test_helper'

class SystemizedSmsSenderTest < ActiveSupport::TestCase
  def setup
    super
    line_item_with_assoc!
    @contact_point = ContactPoint::Sms.create!(user: @user, description: '13459999999')
    @user.create_mappings(@line_item, true)

    @valid_twilio_from_number = "15005550006"
    @valid_twilio_to_number = "15005550010"
    @contact_point = @user.contact_points.create!(type: 'ContactPoint::Sms', description: @valid_twilio_to_number)
    User.stubs(:find_user).returns([@user])
    Broadcast.any_instance.stubs(:send_messages)
    @from = TwilioNumber.first
  end

  test "send_code_instructions should send a code message with instructions" do
    from = TwilioNumber.default_number
    sms = ContactPoint::Sms.new(description: @valid_twilio_to_number)
    sms.save(validate: false)
    @user.update_column(:sms_sent_to_user_state, SmsSentToUserState::ONCE)

    ContactPoint::Sms.any_instance.stubs(:user).returns(@user)
    @user.stubs(:needs_code?).returns(true)

    SmsCodesList.expects(:to_sms).returns('message with codes')
    SystemizedSmsSender.expects(:send_isolated_sms).with(sms, from, 'message with codes')
    SystemizedSmsSender.send(:send_code_instructions, sms, from)
  end

  test 'send_message should fetch a PhoneMapping and a UrlMapping for an update broadcast' do
    broadcast = @line_item.create_opening_broadcast(@user)
    Broadcast.any_instance.stubs(:opening_broadcast?).returns(false)

    PhoneMapping.expects(:mapping_for).twice.returns(@user.phone_mappings.first).with(@user, @line_item)
    UrlMapping.expects(:create_for).returns(UrlMapping.new(code: '12345678')).with(@contact_point, @line_item)
    SystemizedSmsSender.send_message(broadcast, @contact_point)
  end

  test 'send_message should create a SmsMessage record' do
    broadcast = @line_item.create_opening_broadcast(@user)
    assert_difference "SmsMessage.count" do
      SystemizedSmsSender.send_message(broadcast, @contact_point)
    end
  end

  test 'send_message with an opening broadcast should add 2 jobs to DelayedJob' do
    @line_item.expects(:to_sentence).returns('short body')
    broadcast = @line_item.create_opening_broadcast(@user)
    assert_difference "Delayed::Job.count", 2 do
      SystemizedSmsSender.send_message(broadcast, @contact_point)
    end
  end

  test 'send_message with an opening broadcast with long body should add 3 jobs to DelayedJob' do
    broadcast = @line_item.create_opening_broadcast(@user)
    broadcast.body = token_of_length(150)
    assert_difference "Delayed::Job.count", 3 do
      SystemizedSmsSender.send_message(broadcast, @contact_point)
    end
  end

  test 'send_message with an update broadcast should add 1 job to DelayedJob' do
    broadcast = @line_item.create_opening_broadcast(@user)
    broadcast.expects(:opening_broadcast?).returns(false)
    assert_difference "Delayed::Job.count" do
      SystemizedSmsSender.send_message(broadcast, @contact_point)
    end
  end
end