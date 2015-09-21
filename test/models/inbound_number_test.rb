require 'test_helper'

class InboundNumberTest < ActiveSupport::TestCase
  def setup
    super
    r = Request.new
    r.save!(validate: false)
    @number = InboundNumber.new(number: '12345', request: r)
  end

  should validate_presence_of :request
  should validate_presence_of :number
  should validate_uniqueness_of :number

  should have_many :phone_mappings
  should have_many :broadcasts
  should belong_to :request

  test 'number should be just numbers' do
    assert @number.valid?
    @number.assign_attributes(number: '123a45')
    assert @number.invalid?
  end

  test 'voice_number should return number' do
    assert_equal '12345', @number.voice_number('unused')
  end

  test 'resource_full_name should return number' do
    assert_equal '12345', @number.resource_full_name('unused')
  end

  test 'caller_info should return a caller with the reserved number of its request as caller id' do
    @number.request.reserved_number = TwilioNumber.first
    assert_equal TwilioNumber.first.number, @number.caller_info('unused').caller_id
  end

  test 'caller_info should return a caller with no organization_user' do
    @number.request.reserved_number = TwilioNumber.first
    assert_nil @number.caller_info('unused').organization_user
  end

  test 'create_with_mapping! should create an InboundNumber' do
    u = create_user
    request = Request.new
    request.save!(validate: false)
    request.stubs(:author).returns(u)
    assert_difference 'InboundNumber.count' do
      InboundNumber.create_with_mapping!('123456', request)
      assert_equal '123456', InboundNumber.last.number
      assert_equal request, InboundNumber.last.request
    end
  end

  test 'create_with_mapping! should create mappings for the request author' do
    u = create_user
    request = Request.new
    request.save!(validate: false)
    request.stubs(:author).returns(u)
    InboundNumber.stubs(:find_or_create_by!).returns('created inbound')
    u.expects(:create_mappings).with('created inbound', true)
    InboundNumber.create_with_mapping!('123456', request)
  end

  test 'create_with_mapping! should use the existing InboundNumber if there is one with the args passed' do
    u = create_user
    request = Request.new
    request.save!(validate: false)
    request.stubs(:author).returns(u)
    existing = InboundNumber.create!(number: '123456', request: request)
    u.expects(:create_mappings).with(existing, true)
    assert_no_difference 'InboundNumber.count' do
      InboundNumber.create_with_mapping!('123456', request)
    end
  end

  test 'request_author should return the author of the request' do
    u = create_user
    request = Request.new
    request.stubs(:author).returns(u)
    @number.stubs(:request).returns(request)
    assert_equal u, @number.request_author
  end

  test 'mail_prefix should return its number' do
    assert_equal '12345', @number.mail_prefix('anything')
  end

  test 'transfer_broadcasts should update its broadcasts with the new broadcastable and author given' do
    new_broadcastable = LineItem.new
    new_broadcastable.stubs(:populate_from_parent)
    new_broadcastable.save!(validate: false)
    new_org_user = OrganizationUser.new
    new_org_user.save!(validate: false)
    @number.save!
    Broadcast.any_instance.stubs(:send_messages)
    b1 = @number.broadcasts.create!(body: 'body1')
    b2 = @number.broadcasts.create!(body: 'body2')
    @number.send(:transfer_broadcasts, new_broadcastable, new_org_user)
    assert_equal new_broadcastable, b1.broadcastable
    assert_equal new_broadcastable, b2.broadcastable
    assert_equal new_org_user, b1.organization_user
    assert_equal new_org_user, b2.organization_user
  end

  test 'author_mapping should return the active phone mapping whose user is the request author' do
    u = create_user
    @number.save!
    @number.expects(:request_author).returns(u)
    active_mapping = PhoneMapping.create!(entity: @number, user: u, twilio_number: TwilioNumber.default_number)
    assert_equal active_mapping, @number.author_mapping
  end

  test 'organization_user_for should return its request created_by if the user given is the requesting user' do
    u = create_user
    ou = OrganizationUser.new
    @number.save!
    @number.expects(:requesting_user?).with(u).returns(true)
    @number.stubs(:request).returns(stub(created_by: ou))
    assert_equal ou, @number.organization_user_for(u)
  end

  test 'organization_user_for should return nil if the user given is not the requesting user' do
    u = create_user
    @number.save!
    @number.expects(:requesting_user?).with(u).returns(false)
    assert_nil @number.organization_user_for(u)
  end

  test 'requesting_user? should return true if the user given is the request author' do
    u = create_user
    @number.expects(:request_author).returns(u)
    assert @number.requesting_user?(u)
  end

  test 'requesting_user? should return false if the user given is not the request author' do
    u = create_user
    u2 = create_user(name: 'u2', uniqueid: 'u2')
    @number.expects(:request_author).returns(u)
    assert !@number.requesting_user?(u2)
  end

  test 'receiver_contacts should return a new sms contact point whose number is the inbound number number' do
    assert_equal 1, @number.receiver_contacts.length
    contact = @number.receiver_contacts[0]
    assert contact.is_a?(ContactPoint::Sms)
    assert contact.new_record?
    assert_equal '12345', contact.number
  end

  test 'author_contacts should return the notifiable contacts of its request author' do
    u = create_user
    u.expects(:notifiable_contacts).returns('notifiable contacts')
    @number.stubs(:request_author).returns(u)
    assert_equal 'notifiable contacts', @number.author_contacts
  end

  test 'no_replies? should return false' do
    assert !@number.no_replies?
  end

  test 'mapping_path should return its request show url' do
    request = Request.new
    request.stubs(:id).returns('5')
    @number.expects(:request).returns(request)
    assert_equal '/requests/5', @number.mapping_path
  end

  test 'merge_into should call update_receiver on the new broadcastable' do
    request = Request.new
    request.save!(validate: false)
    new_li = request.line_items.build
    new_li.save!(validate: false)
    @number.stubs(:request).returns(request)
    LineItem.any_instance.expects(:update_receiver).with('12345')
    @number.merge_into(new_li.id)
  end

  test 'merge_into should call transfer_broadcasts' do
    request = Request.new
    request.save!(validate: false)
    new_li = request.line_items.build
    new_li.save!(validate: false)
    new_org_user = OrganizationUser.new
    @number.stubs(:request).returns(request)
    LineItem.any_instance.stubs(:update_receiver).returns(new_org_user)
    @number.expects(:transfer_broadcasts).with(new_li, new_org_user)
    @number.merge_into(new_li.id)
  end

  test 'merge_into should destroy the inbound number on success' do
    request = Request.new
    request.save!(validate: false)
    new_li = request.line_items.build
    new_li.save!(validate: false)
    @number.stubs(:request).returns(request)
    LineItem.any_instance.stubs(:update_receiver).with('12345')
    @number.merge_into(new_li.id)
    assert @number.destroyed?
  end

  test 'close should close its mappings' do
    i = InboundNumber.new
    m1 = EmailMapping.new(entity: i)
    m2 = PhoneMapping.new(entity: i)
    m1.expects(:close)
    m2.expects(:close)
    i.stubs(:mappings).returns([m1, m2])
    i.close
  end
end
