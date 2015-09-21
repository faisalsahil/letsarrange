require 'test_helper'

class BroadcastTest < ActiveSupport::TestCase
  should belong_to :organization_user
  should have_one :user
  should belong_to :broadcastable
  should have_many :sms_messages
  should have_many :email_messages

  should validate_presence_of :organization_user
  should validate_presence_of :broadcastable
  should validate_presence_of :body

  def setup
    super
    Broadcast.any_instance.stubs(:send_messages)
    line_item_with_assoc!

    @line_item.stubs(:to_sentence).returns('line item sentence')
  end

  test 'requested_organization should delegate to broadcastable' do
    b = Broadcast.new
    b.expects(:broadcastable).returns(Struct.new(:requested_organization).new('org'))
    assert_equal 'org', b.requested_organization
  end

  test 'request should delegate to broadcastable' do
    b = Broadcast.new
    b.expects(:broadcastable).returns(Struct.new(:request).new('request'))
    assert_equal 'request', b.request
  end

  test 'requesting_organization should delegate to broadcastable' do
    b = Broadcast.new
    b.expects(:broadcastable).returns(Struct.new(:requesting_organization).new('org'))
    assert_equal 'org', b.requesting_organization
  end

  test 'receiver should delegate to broadcastable' do
    b = Broadcast.new
    b.expects(:broadcastable).returns(Struct.new(:receiver).new('receiver'))
    assert_equal 'receiver', b.broadcastable_receiver
  end

  test 'author should delegate to broadcastable' do
    b = Broadcast.new
    b.expects(:broadcastable).returns(Struct.new(:author).new('author'))
    assert_equal 'author', b.broadcastable_author
  end

  test 'send_messages should be called after create' do
    broadcast = Broadcast.new
    broadcast.expects(:send_messages)
    broadcast.save(validate: false)
  end

  test 'opening_broadcast? should return true if its broadcastable does not have replies' do
    broadcast = @line_item.create_opening_broadcast(@user)
    @line_item.expects(:no_replies?).returns(true)
    assert broadcast.opening_broadcast?
  end

  test 'opening_broadcast? should return false if its broadcastable has replies' do
    broadcast = @line_item.create_opening_broadcast(@user)
    @line_item.expects(:no_replies?).returns(false)
    assert !broadcast.opening_broadcast?
  end

  test 'send_messages should call send_message for each target_contact' do
    Broadcast.any_instance.unstub(:send_messages)

    sender = Object.new
    b = Broadcast.new
    b.expects(:target_contacts).returns([ContactPoint.new, ContactPoint.new])
    b.expects(:sender_for_contact).twice.returns(sender)

    sender.expects(:send_message).twice
    b.send(:send_messages)
  end

  test 'send_messages should call send_message on the return value of sender_for_contact' do
    Broadcast.any_instance.unstub(:send_messages)

    sender = Object.new
    sender.expects(:send_message)
    b = Broadcast.new
    b.expects(:target_contacts).returns([ContactPoint.new])
    b.expects(:sender_for_contact).returns(sender)
    b.send(:send_messages)
  end

  test 'to_requested? should return true if its user is a requesting user of the broadcastable' do
    u = create_user(name: 'u2', uniqueid: 'u2')
    ou = OrganizationUser.new(user: u)
    ou.save(validate: false)
    broadcastable = LineItem.new
    broadcastable.expects(:requesting_user?).with(u).returns(true)
    b = Broadcast.new(organization_user: ou)
    b.stubs(:broadcastable).returns(broadcastable)
    assert b.to_requested?
  end

  test 'to_requested? should return false if its user is not a requesting user of the broadcastable' do
    u = create_user(name: 'u2', uniqueid: 'u2')
    ou = OrganizationUser.new(user: u)
    ou.save(validate: false)
    broadcastable = LineItem.new
    broadcastable.expects(:requesting_user?).with(u).returns(false)
    b = Broadcast.new(organization_user: ou)
    b.stubs(:broadcastable).returns(broadcastable)
    assert !b.to_requested?
  end

  test 'author should return the user author of the broadcast' do
    u = User.new
    org_user = OrganizationUser.new(user: u)
    b = Broadcast.new(organization_user: org_user)
    assert_equal u, b.author
  end

  test 'author should return a new user if there is no organization user associated with the broadcast' do
    b = Broadcast.new
    b.stubs(:sender_number).returns('13458888888')
    assert b.author.new_record?
    assert_nil b.organization_user
    assert_equal '(345) 888-8888', b.author.name
  end

  test 'author_name should return the full name of the organization_user' do
    org_user = OrganizationUser.new
    b = Broadcast.new(organization_user: org_user)
    org_user.expects(:full_name).returns('something')
    assert_equal 'something', b.author_name
  end

  test 'author_name should return the denormalized sender number if there is no organization user associated with the broadcast' do
    b = Broadcast.new
    b.stubs(:sender_number).returns('13459999999')
    assert_nil b.organization_user
    assert_equal '(345) 999-9999', b.author_name
  end

  test 'full_body should return the body prepended with the org_user name' do
    org_user = OrganizationUser.new
    org_user.stubs(:full_name).returns('name of org_user')
    b = Broadcast.new(body: 'body', organization_user: org_user)
    assert_equal 'name of org_user: body', b.full_body
  end

  test 'create_with_user should create a broadcast' do
    assert_difference 'Broadcast.count' do
      b = Broadcast.create_with_user(user: @user, broadcastable: @line_item, body: 'some body to love')
      assert_equal 'some body to love', b.body
      assert_equal @line_item, b.broadcastable
      assert_equal @user, b.author
    end
  end

  test 'create_with_user should ask the broadcastable for the organization_user of the user given' do
    ou = OrganizationUser.first
    @line_item.expects(:organization_user_for).with(@user).returns(ou)
    assert_difference('Broadcast.count') do
      created = Broadcast.create_with_user(user: @user, broadcastable: @line_item, body: 'some body to love')
      assert_equal ou, created.organization_user
    end
  end

  test 'for_request? should return true if its broadcastable is an InboundNumber' do
    broadcast = Broadcast.new(broadcastable: InboundNumber.new)
    assert broadcast.send(:for_request?)
  end

  test 'for_request? should return false if its broadcastable is a LineItem' do
    broadcast = Broadcast.new(broadcastable: LineItem.new)
    assert !broadcast.send(:for_request?)
  end

  test 'sender_for_contact should return HumanizedSmsSender if the contact point is a Sms and humanized_sender? is true' do
    b = Broadcast.new
    b.expects(:humanized_sender?).returns(true)
    assert_equal HumanizedSmsSender, b.send(:sender_for_contact, ContactPoint::Sms.new)
  end

  test 'sender_for_contact should return SystemizedSmsSender if the contact point is a Sms and humanized_sender? is false' do
    b = Broadcast.new
    b.expects(:humanized_sender?).returns(false)
    assert_equal SystemizedSmsSender, b.send(:sender_for_contact, ContactPoint::Sms.new)
  end

  test 'sender_for_contact should return EmailSender if the contact point is a Email' do
    assert_equal EmailSender, Broadcast.new.send(:sender_for_contact, ContactPoint::Email.new)
  end

  test 'sender_for_contact should return VoiceBroadcastSender if the contact point is a Voice' do
    assert_equal VoiceBroadcastSender, Broadcast.new.send(:sender_for_contact, ContactPoint::Voice.new)
  end

  test 'target_contacts should return the author_contacts of its broadcastable if it is not to_requested?' do
    inbound = InboundNumber.new
    b = Broadcast.new(broadcastable: inbound)
    b.expects(:to_requested?).returns(false)
    inbound.expects(:author_contacts).returns([ContactPoint.new])
    b.send(:target_contacts)
  end

  test 'target_contacts should return the receiver_contacts of its broadcastable if it is to_requested?' do
    inbound = InboundNumber.new
    b = Broadcast.new(broadcastable: inbound)
    b.expects(:to_requested?).returns(true)
    inbound.expects(:receiver_contacts).returns([ContactPoint.new])
    b.send(:target_contacts)
  end

  test 'target_contacts should exclude voice contacts if there is any sms contact' do
    inbound = InboundNumber.new
    b = Broadcast.new(broadcastable: inbound)
    b.stubs(:to_requested?).returns(true)
    sms_cp = ContactPoint::Sms.new(description: '13451111111')
    voice_cp = ContactPoint::Voice.new(description: '13451111112')
    inbound.stubs(:receiver_contacts).returns([voice_cp, sms_cp])
    assert_equal [sms_cp], b.send(:target_contacts)
  end

  test 'target_contacts should not exclude voice contacts if there is no sms contact' do
    inbound = InboundNumber.new
    b = Broadcast.new(broadcastable: inbound)
    b.stubs(:to_requested?).returns(true)
    voice_cp = ContactPoint::Voice.new(description: '13451111111')
    voice_cp2 = ContactPoint::Voice.new(description: '13451111112')
    inbound.stubs(:receiver_contacts).returns([voice_cp, voice_cp2])
    assert_equal [voice_cp, voice_cp2], b.send(:target_contacts)
  end

  test 'fake_author should return the user with a sms contact point that matchs the sender_number' do
    ContactPoint::Sms.create!(user: @user, description: '13456546546')
    b = Broadcast.new
    b.expects(:sender_number).returns('13456546546')
    assert_equal @user, b.fake_author
  end

  test 'fake_author should return a new user if there is no user with a sms contact point that matchs the sender_number' do
    assert !ContactPoint::Sms.where(description: '13456546546').exists?
    b = Broadcast.new
    b.expects(:sender_number).twice.returns('13456546546')
    fake_author = b.fake_author
    assert fake_author.new_record?
    assert_equal '(345) 654-6546', fake_author.name
  end

  test 'inbound_number should return its broadcastable' do
    something = InboundNumber.new
    b = Broadcast.new(broadcastable: something)
    assert_equal something, b.inbound_number
  end

  test 'of_inbound_numbers should return the broadcasts whose broadcastable is one of the given inbound numbers' do
    i1 = InboundNumber.create!(number: '13451234567', request: @line_item.request)
    i2 = InboundNumber.create!(number: '13451234568', request: @line_item.request)
    i3 = InboundNumber.create!(number: '13451234569', request: @line_item.request)
    li4 = @line_item
    b1 = Broadcast.create!(broadcastable: i1, body: 'body1')
    b2 = Broadcast.create!(broadcastable: i2, body: 'body2')
    b3 = Broadcast.create!(broadcastable: i3, body: 'body3')
    b4 = Broadcast.create!(broadcastable: li4, body: 'body4', organization_user: OrganizationUser.first)
    assert_equal [b1, b2], Broadcast.of_inbound_numbers([i1, i2]).order(:body).to_a
  end

  test 'humanized_sender? should return true if humanized_messages? is true and to_requested? is true' do
    b = Broadcast.new
    b.stubs(:humanized_messages?).returns(true)
    b.stubs(:to_requested?).returns(true)
    assert b.humanized_sender?
  end

  test 'humanized_sender? should return false if humanized_messages? is false' do
    b = Broadcast.new
    b.stubs(:humanized_messages?).returns(false)
    b.stubs(:to_requested?).returns(true)
    assert !b.humanized_sender?
  end

  test 'humanized_sender? should return false if to_requested? is false' do
    b = Broadcast.new
    b.stubs(:humanized_messages?).returns(true)
    b.stubs(:to_requested?).returns(false)
    assert !b.humanized_sender?
  end
end