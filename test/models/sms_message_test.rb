require 'test_helper'
require 'ostruct'

class SmsMessageTest < ActiveSupport::TestCase
  
  def setup
    super
    broadcast = Broadcast.new
    broadcast.stubs(:send_messages)
    broadcast.save(validate: false)

    @message = SmsMessage.new(to: "555 555 55555", from: "555 555 55556", body: "Hello", broadcast: broadcast)
    @user = create_user
    @contact_point1 = ContactPoint::Sms.create!(description: '14157637901', user: @user)

    request = Request.new(time_zone: "Buenos Aires", earliest_start: Time.now, finish_by: Time.now)
    request.save(validate: false)

    @line_item1 = LineItem.new request: request
    @line_item1.stubs(:populate_from_parent).returns(true)
    @line_item1.save(validate: false)
    @line_item2 = LineItem.new request: request
    @line_item2.stubs(:populate_from_parent).returns(true)
    @line_item2.save(validate: false)

    @number = TwilioNumber.first
  end

  should belong_to :broadcast

  should validate_presence_of :from
  should validate_presence_of :to
  should validate_presence_of :body

  test 'it should respond to update_from' do
    assert_respond_to @message, :update_from
  end

  test 'update_from should update an existing message with the values provided' do
    @message.save
    m = OpenStruct.new sid: "144444",
              status: "sent", uri: "some_uri"

    @message.update_from m

    assert_equal m.sid, @message.sid
    assert_equal m.status, @message.status
    assert_equal m.uri, @message.uri
  end

  test "it should respond to get_line" do
    assert @message.respond_to?(:fetch_mapping, true)
  end

  test "fetch_mapping should get a mapping for a given message" do
    mapping = PhoneMapping.create_for(@user, @line_item1, @number)

    PhoneMapping.stubs(:parse_code).returns(1)

    response = SmsMessage.new from: @contact_point1.number, to: @number.number, body: "Im fine"

    assert_equal mapping, response.send(:fetch_mapping, @number, @contact_point1.user)
  end

  test "fetch_mapping should route the message for the mapping if there is no code and there is only one mapping" do
    m1 = PhoneMapping.create_for(@user, @line_item1, @number)
    PhoneMapping.stubs(:parse_code).returns(nil)

    response = SmsMessage.new(from: @contact_point1.number, to: @number.number, body: "Im fine")

    assert_equal m1, response.send(:fetch_mapping, @number, @user)
  end

  test "fetch_mapping should raise an InvalidCodeException if there are more than one mapping but the message doesn't have a code" do
    response = SmsMessage.new(from: @contact_point1.number, body: 'Hey There how are u?', to: @number.number)

    PhoneMapping.create_for(@user, @line_item1, @number)
    PhoneMapping.create_for(@user, @line_item2, @number)

    assert_raises(InvalidCodeException) do
      response.send(:fetch_mapping, @number, @user)
    end
  end

  test "fetch_mapping should raise a NoRouteException if there is no mapping" do
    response = SmsMessage.new
    response.stubs(:from).returns("555")
    response.stubs(:body).returns("Hey There how are u?")

    assert_raises(NoRouteFoundException) do
      response.send(:fetch_mapping, @number, @user)
    end
  end

  test "fetch_mapping should raise a NoRouteException if the user given is nil" do
    response = SmsMessage.new
    response.stubs(:from).returns("555")
    response.stubs(:body).returns("Hey There how are u?")

    assert_raises(NoRouteFoundException) do
      response.send(:fetch_mapping, @number, nil)
    end
  end

  test "fetch_mapping should raise an InvalidCodeException if it receives an invalid code" do
    response = SmsMessage.new(from: @contact_point1.number, body: '3 Hey There how are u?', to: @number.number)

    PhoneMapping.create_for(@user, @line_item1, @number)
    PhoneMapping.create_for(@user, @line_item2, @number)

    assert_raises(InvalidCodeException) do
      response.send(:fetch_mapping, @number, @user)
    end
  end

  test 'to_backend? should return true if the to number is a twilio number' do
    message = SmsMessage.new(to: TwilioNumber.default_number.number)
    assert message.to_backend?
  end

  test 'to_backend? should return false if the to number is not a twilio number' do
    message = SmsMessage.new(to: TwilioNumber.default_number.number.succ)
    assert !message.to_backend?
  end

  test 'with_number scope should return the records that are linked to a broadcast and has the number given as from or to' do
    a = SmsMessage.create!(body: 'body', broadcast_id: 123, from: 'some_number', to: 'some_to')
    b = SmsMessage.create!(body: 'body', broadcast_id: 1234, from: 'some_from', to: 'some_number')

    SmsMessage.create!(body: 'body', broadcast_id: 12345, from: 'some_from', to: 'some_to')
    SmsMessage.create!(body: 'body', from: 'some_number', to: 'some_to')
    SmsMessage.create!(body: 'body', from: 'some_from', to: 'some_number')
    SmsMessage.create!(body: 'body', from: 'some_from', to: 'some_to')

    assert_equal [a, b], SmsMessage.with_number('some_number').to_a
  end

  test 'rebuild_broadcast should call build_broadcast_from_reserved if the to number is reserved' do
    from_cp = ContactPoint::Sms.create!(user: @user, number: '13451231231')
    reserved = TwilioNumber.create!(number: 'number')
    Request.new(reserved_number: reserved).save!(validate: false)
    assert reserved.reserved?
    message = SmsMessage.new(to: 'number', from: '13451231231')
    message.expects(:build_broadcast_from_reserved).with(reserved, from_cp)
    message.rebuild_broadcast
  end

  test 'rebuild_broadcast should call build_broadcast_from_mapping if the to number is not reserved' do
    ContactPoint::Sms.create!(user: @user, number: '13451231231')
    reserved = TwilioNumber.create!(number: 'number')
    assert !reserved.reserved?
    message = SmsMessage.new(to: 'number', from: '13451231231')
    message.expects(:build_broadcast_from_mapping).with(reserved, @user)
    message.rebuild_broadcast
  end

  test 'build_broadcast_from_mapping should use fetch_mapping to get the mapping' do
    message = SmsMessage.new(body: 'body')
    message.expects(:fetch_mapping).with('to_number', 'author').returns(PhoneMapping.new)
    Broadcast.stubs(:create_with_user)
    message.send(:build_broadcast_from_mapping, 'to_number', 'author')
  end

  test 'build_broadcast_from_mapping should use body_without_code as the broadcast body' do
    message = SmsMessage.new(body: 'original body')
    message.stubs(:fetch_mapping).returns(PhoneMapping.new(code: '1'))
    message.expects(:body_without_code).with('1').returns('body without code')
    Broadcast.expects(:create_with_user).with(broadcastable: nil, user: 'author', body: 'body without code')
    message.send(:build_broadcast_from_mapping, 'to_number', 'author')
  end

  test 'build_broadcast_from_mapping should create and assign a broadcast' do
    Broadcast.any_instance.stubs(:send_messages)
    message = SmsMessage.new(body: 'some body')
    org = Organization.create!(name: 'org', uniqueid: 'uid')
    org.add_user(@user)
    @line_item1.stubs(:requesting_organization).returns(org)
    message.stubs(:fetch_mapping).returns(PhoneMapping.new(entity: @line_item1))
    assert_difference 'Broadcast.count' do
      message.send(:build_broadcast_from_mapping, TwilioNumber.first.number, @user)
      assert_equal Broadcast.last, message.broadcast
    end
  end

  test 'build_broadcast_from_reserved should fetch the receiver for reserved message of the request' do
    from_cp = ContactPoint::Sms.new(description: '13453213213')
    request = Request.new
    request.save!(validate: false)
    twilio = TwilioNumber.create!(number: 'number')
    twilio.stubs(:request).returns(request)
    request.expects(:receiver_for_reserved_message).with(from_cp)
    Broadcast.stubs(:create_with_user)

    message = SmsMessage.new
    message.send(:build_broadcast_from_reserved, twilio, from_cp)
  end

  test 'build_broadcast_from_reserved should create a broadcast for the receiver returned by the request' do
    from_cp = ContactPoint::Sms.new(description: '13453213213', user: @user)
    Broadcast.any_instance.stubs(:send_messages)
    request = Request.new
    request.save!(validate: false)
    request.stubs(:receiver_for_reserved_message).returns(@line_item1)
    twilio = TwilioNumber.create!(number: 'number')
    twilio.stubs(:request).returns(request)
    org = Organization.create!(name: 'org', uniqueid: 'uid')
    org.add_user(@user)
    @line_item1.stubs(:requesting_organization).returns(Organization.new)
    @line_item1.stubs(:requested_organization).returns(org)

    message = SmsMessage.new(body: 'some body')
    assert_difference 'Broadcast.count' do
      message.send(:build_broadcast_from_reserved, twilio, from_cp)
      Broadcast.last.tap do |b|
        assert_equal b, message.broadcast
        assert_equal b.broadcastable, @line_item1
        assert_equal b.author, @user
      end
    end
  end

  test 'body_without_code should remove the initial code of the body if it matchs the code given' do
    assert_equal 'unchanged body', SmsMessage.new(body: 'unchanged body').send(:body_without_code, '1')
    assert_equal '2 body with a random number', SmsMessage.new(body: '2 body with a random number').send(:body_without_code, '1')
    assert_equal 'body with matching code', SmsMessage.new(body: '1 body with matching code').send(:body_without_code, '1')
    assert_equal 'body with code and lot of whitespaces', SmsMessage.new(body: '1          body with code and lot of whitespaces').send(:body_without_code, '1')
  end
end