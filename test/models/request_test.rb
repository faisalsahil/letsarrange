require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  should validate_presence_of :organization
  should validate_presence_of :time_zone

  should belong_to :organization_resource
  should have_one :organization

  should have_many :line_items
  should have_many :inbound_numbers
  should have_many :requested_organizations
  should belong_to :last_edited
  should belong_to :contact_point
  should belong_to :reserved_number

  test 'default value for length should be 1:00' do
    request = Request.new
    assert_equal request.length, '1:00'

    request = Request.new(length: '2:00')
    assert_equal request.length, '2:00'
  end

  test 'closed? should return true if the status is closed' do
    request = Request.new(status: RequestState::CLOSED)
    assert request.closed?
  end

  test 'closed? should return false if the status is not closed' do
    request = Request.new(status: RequestState::OFFERED)
    assert ! request.closed?
  end

  test 'reopen should change the status to offered' do
    request = Request.new
    request.expects(:change_status).with(:offered)
    request.reopen
  end

  test 'close should add an error if the request is already closed' do
    request = Request.new(status: RequestState::CLOSED)
    request.close(User.new)
    assert_equal 'Request already closed', request.errors_sentence
  end

  test 'close should call close_dependencies if the request is not closed yet' do
    u = User.new
    request = Request.new
    request.expects(:close_dependencies).with(broadcast_sender: u)
    request.close(u)
  end

  test 'close_dependencies should change the status to closed' do
    org = Organization.create!(name: 'n', uniqueid: 'n')
    user = create_user
    org.add_user(user)
    request = Request.new(organization: org)
    request.save(validate: false)
    assert !request.closed?
    request.close_dependencies(broadcast_sender: user)
    assert request.closed?
  end

  test 'close_dependencies should clear the reserved number' do
    org = Organization.create!(name: 'n', uniqueid: 'n')
    user = create_user
    org.add_user(user)
    tn = TwilioNumber.default_number
    request = Request.new(organization: org, reserved_number: tn)
    request.save(validate: false)
    assert_equal tn, request.reserved_number
    request.close_dependencies(broadcast_sender: user)
    assert_nil request.reserved_number
  end

  test 'close_dependencies should close any line items that remain open' do
    Broadcast.any_instance.stubs(:send_messages)
    org = Organization.create!(name: 'n', uniqueid: 'n')
    user = create_user
    org.add_user(user)
    request = Request.new(organization_resource: user.default_org_resource)

    request.save(validate: false)

    line_item_1 = LineItem.new(request: request)
    line_item_1.save(validate: false)

    line_item_2 = LineItem.new(request: request)
    line_item_2.save(validate: false)

    request.stubs(:line_items).returns(stub(open: [line_item_1, line_item_2]))
    line_item_1.expects(:close).with(broadcast_sender: user, close_request: false)
    line_item_2.expects(:close).with(broadcast_sender: user, close_request: false)
    request.close_dependencies(broadcast_sender: user)
  end

  test 'close_dependencies should close its inbound numbers' do
    request = Request.new
    request.save(validate: false)
    i1 = InboundNumber.new(number: '13451234567', request: request)
    i2 = InboundNumber.new(number: '13451234568', request: request)
    i1.expects(:close)
    i2.expects(:close)
    request.inbound_numbers = [i1, i2]
    request.close_dependencies
  end

  test 'open should include requests that are not closed' do
    open = Request.new
    open.save(validate: false)
    closed = Request.new(status: RequestState::CLOSED)
    closed.save(validate: false)
    assert_equal [open], Request.open.to_a
  end

  test 'with_reserved_number should include requests that have an reserved_number set' do
    without = Request.new
    without.save(validate: false)
    with = Request.new(reserved_number: TwilioNumber.last)
    with.save(validate: false)
    assert_equal [with], Request.with_reserved_number.to_a
  end

  test 'assign_reserved_number should set reserved_number to an available twilio number if the request is non branded' do
    r = Request.new(message_branding: MessageBrandingState::HUMANIZED)
    assert_nil r.reserved_number
    r.send(:assign_reserved_number, '345')
    assert_equal TwilioNumber.first, r.reserved_number
  end

  test 'assign_reserved_number should do nothing if the request is branded' do
    r = Request.new(message_branding: MessageBrandingState::SYSTEMIZED)
    r.send(:assign_reserved_number, '345')
    assert_nil r.reserved_number
  end

  test 'voice_number should call voice_number on the author' do
    author = User.new
    author.expects(:voice_number).returns('number')
    r = Request.new(created_by: OrganizationUser.new(user: author))
    assert_equal 'number', r.voice_number
  end

  test 'resource_name should return the organization resource full_name' do
    o = OrganizationResource.new
    o.expects(:full_name).returns('user at org')
    r = Request.new(organization_resource: o)
    assert_equal 'user at org', r.resource_name
  end

  test 'line_item_of_requested_user should return the line item whose receiver is the user given' do
    r = Request.new
    r.save!(validate: false)
    o1 = Organization.create!(name: 'o1', uniqueid: 'o1')
    u1 = create_user(name: 'u1', uniqueid: 'u1')
    ou1 = o1.add_user(u1)
    o2 = Organization.create!(name: 'o2', uniqueid: 'o2')
    u2 = create_user(name: 'u2', uniqueid: 'u2')
    ou2 = o2.add_user(u2)
    u3 = create_user(name: 'u3', uniqueid: 'u3')

    l1 = LineItem.new(created_for: ou1, request: r)
    l1.save!(validate: false)
    l2 = LineItem.new(created_for: ou2, request: r)
    l2.save!(validate: false)


    assert_equal l1, r.line_item_of_requested_user(u1)
    assert_equal l2, r.line_item_of_requested_user(u2)
    assert_nil r.line_item_of_requested_user(u3)
  end

  test 'line_item_of_requested_user should return nil if the user given is nil' do
    assert_nil Request.new.line_item_of_requested_user(nil)
  end

  test 'author should return the user that created the request' do
    u = create_user
    org_user = OrganizationUser.new(user: u)
    org_user.save!(validate: false)
    r = Request.new(created_by: org_user)
    assert_equal u, r.author
  end

  test 'broadcasts should return the broadcasts related to inbound numbers of the request' do
    Broadcast.any_instance.stubs(:send_messages)
    r = Request.new
    r.save!(validate: false)
    r2 = Request.new
    r2.save!(validate: false)
    i1 = InboundNumber.create!(number: '12345', request: r)
    i2 = InboundNumber.create!(number: '123456', request: r)
    i3 = InboundNumber.create!(number: '1234567', request: r2)
    b1 = i1.broadcasts.create!(body: 'b1')
    b2 = i2.broadcasts.create!(body: 'b2')
    b3 = i3.broadcasts.create!(body: 'b3')

    assert_equal [b1, b2], r.broadcasts.order(:body).to_a
  end

  test 'one_line_item? should return true if it has only one line item' do
    r = Request.new
    r.save!(validate: false)
    li = LineItem.new(request: r)
    li.save!(validate: false)
    assert r.one_line_item?
  end

  test 'one_line_item? should return false if it has more than one line items' do
    r = Request.new
    r.save!(validate: false)
    li = LineItem.new(request: r)
    li.save!(validate: false)
    li2 = LineItem.new(request: r)
    li2.save!(validate: false)
    assert !r.one_line_item?
  end

  test 'first_line_item should return its first line item' do
    r = Request.new
    r.save!(validate: false)
    li = LineItem.new(request: r)
    li.save!(validate: false)
    li2 = LineItem.new(request: r)
    li2.save!(validate: false)
    assert_equal li, r.first_line_item
  end

  test 'receiver_for_reserved_message should return its line item if there is only one' do
    li = LineItem.new
    li.stubs(:populate_from_parent)
    li.save!(validate: false)
    li.expects(:update_receiver).with('13459999999')
    li.stubs(:receiver)
    r = Request.new
    r.save!(validate: false)
    r.expects(:first_line_item).returns(li)
    r.expects(:one_line_item?).returns(true)

    assert_equal li, r.receiver_for_reserved_message(ContactPoint::Sms.new(number: '13459999999'))
  end

  test 'receiver_for_reserved_message should return its line item whose requested user is the user of the contact point given' do
    r = Request.new
    r.save!(validate: false)
    r.expects(:one_line_item?).returns(false)
    u = create_user
    ou = OrganizationUser.new(user: u)
    ou.save!(validate: false)
    li = LineItem.new(request: r, created_for: ou)
    li.save!(validate: false)

    assert_equal li, r.receiver_for_reserved_message(ContactPoint::Sms.new(user: u, number: '13459999999'))
  end

  test 'receiver_for_reserved_message should return a newly created inbound number for the number of the contact point given if there is no matching line item' do
    r = Request.new(reserved_number: TwilioNumber.default_number)
    r.save!(validate: false)
    r.expects(:one_line_item?).returns(false)
    r.expects(:line_item_of_requested_user).returns(nil)

    InboundNumber.expects(:create_with_mapping!).with('13459999999', r).returns('created inbound')
    assert_equal 'created inbound', r.receiver_for_reserved_message(ContactPoint::Sms.new(number: '13459999999'))
  end
end