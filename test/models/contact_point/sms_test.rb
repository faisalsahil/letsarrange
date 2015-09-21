require 'test_helper'

class ContactPoint::SmsTest < ActiveSupport::TestCase
  def setup
    super
    @user = create_user
    @contact_point = ContactPoint::Sms.new(user: @user, description: '(345) 123-4567')
    @number = TwilioNumber.default_number
  end

  test 'can_clone_to_voice? should check if a voice with the same number exists' do
    cp = ContactPoint::Voice.new(number: '13454567890')
    cp.save(validate: false)
    @contact_point.number = '(345) 456-7890'
    assert !@contact_point.can_clone_to_voice?

    @contact_point.number = '(345) 456-7891'
    assert @contact_point.can_clone_to_voice?
  end

  test 'it sould include SmsVerifiable' do
    assert_includes ContactPoint::Sms.ancestors, SmsVerifiable
  end

  test 'it should validate uniqueness of sms' do
    cp = ContactPoint::Sms.new(description: '13454567890', user_id: 9999)
    cp.save(validate: false)

    @contact_point.description = '(345) 456-7890'
    assert @contact_point.invalid?
  end

  test 'sms_sent_and_received should return the sms_messages with from or to equal to its description' do
    @contact_point.description = '13451231231'
    s1 = SmsMessage.create!(to: '13451231231', from: '99999999999', body: 'body', broadcast_id: 1234)
    s2 = SmsMessage.create!(to: '99999999999', from: '13451231231', body: 'body', broadcast_id: 1234)
    SmsMessage.create!(to: '99999999999', from: '99999999998', body: 'body', broadcast_id: 1234)
    assert_equal [s1, s2], @contact_point.sms_sent_and_received.to_a
  end

  test 'send_password_reset should relay on SmsSender' do
    cp = ContactPoint::Sms.new
    SmsSender.expects(:send_password_reset).with(cp, '123456')
    cp.send_password_reset('123456')
  end
end