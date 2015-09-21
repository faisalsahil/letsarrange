require 'test_helper'

class HumanizedSmsSenderTest < ActiveSupport::TestCase
  def setup
    super
    line_item_with_assoc!

    @valid_twilio_from_number = "15005550006"
    @valid_twilio_to_number = "15005550010"
    @contact_point = @user.contact_points.create!(type: 'ContactPoint::Sms', description: @valid_twilio_to_number)

    User.stubs(:find_user).returns([@user])
    Broadcast.any_instance.stubs(:send_messages)
    @from = TwilioNumber.first
    @line_item.request.reserved_number = @from
  end

  test 'send_message should create a SmsMessage record' do
    broadcast = @line_item.create_opening_broadcast(@user)
    assert_difference "SmsMessage.count" do
      HumanizedSmsSender.send_message(broadcast, @contact_point)
    end
  end

  test 'send_message with an opening broadcast should add 1 job to DelayedJob' do
    broadcast = @line_item.create_opening_broadcast(@user)
    assert_difference "Delayed::Job.count" do
      HumanizedSmsSender.send_message(broadcast, @contact_point)
    end
  end

  test 'send_message with an opening broadcast with long body should add 1 job to DelayedJob' do
    broadcast = @line_item.create_opening_broadcast(@user)
    broadcast.expects(:to_humanized_sentence).returns(token_of_length(200))
    assert_difference "Delayed::Job.count" do
      HumanizedSmsSender.send_message(broadcast, @contact_point)
    end
  end

  test 'send_message with an update broadcast should add 1 job to DelayedJob' do
    broadcast = @line_item.create_opening_broadcast(@user)
    broadcast.expects(:opening_broadcast?).returns(false)
    assert_difference "Delayed::Job.count" do
      HumanizedSmsSender.send_message(broadcast, @contact_point)
    end
  end

  test 'send_initial should call send_broadcast with initial_body' do
    HumanizedSmsSender.expects(:initial_body).with('broadcast').returns('initial body')
    HumanizedSmsSender.expects(:send_broadcast).with('broadcast', 'to', 'from', 'initial body')
    HumanizedSmsSender.send(:send_initial, 'broadcast', 'to', 'from')
  end

  test 'send_update should call send_broadcast with update_body' do
    HumanizedSmsSender.expects(:update_body).with('broadcast').returns('update body')
    HumanizedSmsSender.expects(:send_broadcast).with('broadcast', 'to', 'from', 'update body')
    HumanizedSmsSender.send(:send_update, 'broadcast', 'to', 'from')
  end

  test 'send_broadcast should create a SmsMessage' do
    broadcast = Broadcast.new
    broadcast.save!(validate: false)
    assert_difference 'SmsMessage.count' do
      HumanizedSmsSender.send(:send_broadcast, broadcast, @contact_point, @from, 'body')
      SmsMessage.last.tap do |created|
        assert_equal 'body', created.body
        assert_equal @contact_point.number, created.to
        assert_equal @from.number, created.from
        assert_equal broadcast, created.broadcast
      end
    end
  end

  test 'send_broadcast should deliver the message created' do
    broadcast = Broadcast.new
    broadcast.save!(validate: false)
    HumanizedSmsSender.expects(:delay).returns(HumanizedSmsSender)
    HumanizedSmsSender.expects(:deliver_sms_message)
    HumanizedSmsSender.send(:send_broadcast, broadcast, @contact_point, @from, 'body')
  end

  test 'initial_body should return Hi, this is author. followed by the humanized sentence of the broadcast' do
    broadcast = Broadcast.new
    broadcast.expects(:author_name).returns('author')
    broadcast.expects(:to_humanized_sentence).returns('sentenced broadcast')
    assert_equal 'Hi, this is author. sentenced broadcast', HumanizedSmsSender.send(:initial_body, broadcast)
  end

  test 'update_body should return the body of the broadcast without author' do
    broadcast = Broadcast.new(body: 'some body to love')
    assert_equal 'some body to love', HumanizedSmsSender.send(:update_body, broadcast)
  end
end