require 'test_helper'

class Communication::SmsControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    line_item_with_assoc!

    @from = TwilioNumber.default_number
    @to = '14157637901'
    @contact_point = ContactPoint::Sms.new(description: @to, user: @user)
    @contact_point.save(validate: false)
  end

  test 'inbound should save the sms received' do
    Broadcast.any_instance.stubs(:send_messages)
    PhoneMapping.create_for(@user, @line_item, @from)

    assert_difference "SmsMessage.count" do
      post_sms
      assert_response :success
    end
  end

  test 'inbound should save a broadcast related to the sms received' do
    Broadcast.any_instance.stubs(:send_messages)
    PhoneMapping.create_for(@user, @line_item, @from)

    assert_difference "Broadcast.count" do
      post_sms
      assert_response :success
    end
  end

  test "inbound should send back a sms if the sms received can't be routed" do
    SmsSender.expects(:delay).returns(SmsSender)
    SmsSender.expects(:deliver_sms)
    post_sms
  end

  test 'inbound should respond with 401 unauthorized if the http authentication fails' do
    auth_headers = { 'HTTP_AUTHORIZATION' => "Basic #{ ::Base64.encode64("#{ ENV['TWILIO_HTTP_USER'].succ }:#{ ENV['TWILIO_HTTP_PASSWORD'].succ }") }" }
    post '/communication/sms/inbound', { data: 'data' }, auth_headers
    assert_response(401)
  end

  def post_sms
    auth_headers = { 'HTTP_AUTHORIZATION' => "Basic #{ ::Base64.encode64("#{ ENV['TWILIO_HTTP_USER'] }:#{ ENV['TWILIO_HTTP_PASSWORD'] }") }" }
    post '/communication/sms/inbound', {'AccountSid'=>'AC8244bade3dd5dd45e13ec70b9a7763eb',
                                        'MessageSid'=>'SMda6ae181970401ec3bd3cd2ceaeccd4b',
                                        'Body'=>'David says good morning', 'ToZip'=>'27536',
                                        'ToCity'=>'RALEIGH', 'FromState'=>'CA', 'ToState'=>'NC',
                                        'SmsSid'=>'SMda6ae181970401ec3bd3cd2ceaeccd4b', 'To'=>"+#{ @from.number }",
                                        'ToCountry'=>'US', 'FromCountry'=>'US',
                                        'SmsMessageSid'=>'SMda6ae181970401ec3bd3cd2ceaeccd4b',
                                        'ApiVersion'=>'2010-04-01', 'FromCity'=>'IGNACIO', 'SmsStatus'=>'received',
                                        'NumMedia'=>'0', 'From'=>"+#{ @to }", 'FromZip'=>'94949'}, auth_headers
  end
end