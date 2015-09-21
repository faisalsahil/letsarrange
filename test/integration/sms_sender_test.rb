require 'test_helper'

class SmsSenderTest < ActiveSupport::TestCase
  def setup
    super
    line_item_with_assoc!

    @valid_twilio_from_number = "15005550006"
    @valid_twilio_to_number = "15005550010"
    @contact_point = @user.contact_points.create!(type: 'ContactPoint::Sms', description: @valid_twilio_to_number)
    User.stubs(:find_user).returns([@user])
    Broadcast.any_instance.stubs(:send_messages)
    @from = TwilioNumber.first
  end

  test 'it should respond to deliver sms' do
    assert_respond_to SmsSender, :deliver_sms
  end

  test 'deliver_sms_message should send an SmsMessage' do
    broadcast = @line_item.create_opening_broadcast(@user)
    sms_message = broadcast.sms_messages.create(to:  @valid_twilio_to_number, from: @valid_twilio_from_number, body: 'Test message')
    sms_message = SmsSender.deliver_sms_message(sms_message.id)
    assert_not_nil sms_message.sid
  end

  test 'it should respond to send_isolated_sms' do
    assert_respond_to SmsSender, :send_isolated_sms
  end

  test "send_isolated_sms should send an sms without creating a SmsMessage" do
    to = Struct.new(:number).new('to_number')
    from = Struct.new(:number).new('from_number')
    SmsSender.expects(:delay).returns(SmsSender)
    SmsSender.expects(:deliver_sms).with('to_number', 'from_number', 'some body')
    assert_no_difference "SmsMessage.count" do
      SmsSender.send_isolated_sms(to, from, 'some body')
    end
  end

  test 'send_verification should send the code in the message' do
    @contact_point.confirmation_token = '123456'
    SmsSender.expects(:send_isolated_sms).with { |to, _, body| to == @contact_point && body['123456'] }
    SmsSender.send_verification(@contact_point)
  end

  test 'send_verification should add a full url mapping' do
    @contact_point.confirmation_token = '123456'
    SmsSender.expects(:send_isolated_sms).with do |to, _, body|
      to == @contact_point && body["Your lets arrange verification code is 123456, or you can go to #{ UrlMapping.last.to_url }"]
    end
    SmsSender.send_verification(@contact_point)
  end

  test 'send_verification should add a new row to the delayed_jobs table' do
    assert_difference "Delayed::Job.count" do
      SmsSender.send_verification(@contact_point)
    end
  end

  test 'send_exception_message should call deliver_sms' do
    SmsSender.expects(:delay).returns(SmsSender)
    SmsSender.expects(:deliver_sms)
    SmsSender.send_exception_message(NoRouteFoundException.new, @valid_twilio_to_number, @valid_twilio_from_number)
  end

  test 'send_exception_message should send the right message depending on the excepcion given' do
    SmsSender.expects(:delay).returns(SmsSender).times(2)

    mapping = PhoneMapping.new(code: '17')
    mapping.stubs(:resource_name).returns('org-res-name')
    mapping2 = PhoneMapping.new(code: '52')
    mapping2.stubs(:resource_name).returns('org-res-name2')
    SmsSender.expects(:deliver_sms).with { |_, _, message| message["Begin replies with 17 (org-res-name) or 52 (org-res-name2). Or go to "] }
    SmsSender.send_exception_message(InvalidCodeException.new([mapping, mapping2]), @valid_twilio_to_number, @valid_twilio_from_number)

    SmsSender.expects(:deliver_sms).with { |_, _, message| message["We got your text, but we don't know what to do with it. Don't worry - go to"] }
    SmsSender.send_exception_message(NoRouteFoundException.new, @valid_twilio_to_number, @valid_twilio_from_number)
  end

  test 'send_password_reset should create a UrlMapping to the reset url' do
    UrlMapping.expects(:static_mapping).with(:edit_user_password, reset_password_token: 'token')
    SmsSender.stubs(:send_isolated_sms)
    SmsSender.stubs(:password_reset_body)
    SmsSender.send_password_reset(ContactPoint::Sms.new, 'token')
  end

  test 'send_password_reset should build the body of the sms via password_reset_body' do
    mapping = UrlMapping.new
    UrlMapping.stubs(:static_mapping).returns(mapping)
    SmsSender.stubs(:send_isolated_sms)
    SmsSender.expects(:password_reset_body).with(mapping)
    SmsSender.send_password_reset(ContactPoint::Sms.new, 'token')
  end

  test 'send_password_reset should send an isolated sms' do
    cp = ContactPoint::Sms.new(description: '13451234567')
    UrlMapping.stubs(:static_mapping)
    SmsSender.stubs(:password_reset_body).returns('sms body')
    SmsSender.expects(:send_isolated_sms).with(cp, TwilioNumber.default_number, 'sms body')
    SmsSender.send_password_reset(cp, 'token')
  end

  test 'password_reset_body should return the body of the password reset sms' do
    mapping = UrlMapping.new
    mapping.stubs(:to_short_url).returns('url.com/reset')
    assert_equal 'Someone has requested a link to change your letsarrange.com password. You can do this through url.com/reset', SmsSender.send(:password_reset_body, mapping)
  end
end