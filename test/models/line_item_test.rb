require 'test_helper'

class LineItemTest < ActiveSupport::TestCase
	def setup
    super
    @user    = create_user(name: 'user', uniqueid: 'user', sms_sent_to_user_state: SmsSentToUserState::NEVER)
    orguser  = @user.organization_user_for(@user.default_org_resource.organization)
    @request = Request.create(organization_resource: @user.default_org_resource,
                              created_by: orguser,
                              earliest_start: Time.now,
                              ideal_start: Time.now,
                              finish_by: (Time.now + 1.hour),
								              length: "1:00",
                              description: "Massage",
								              location: "My Place",
                              offer: '$100',
                              comment: "this is a comment!")

		resource = Resource.create(name: "resource1", uniqueid: "resource1")
    user2 = create_user(name: 'requestee', uniqueid: 'requestee')
		org1     = Organization.create(name: "org1", uniqueid: "org1")
    org1.add_user(user2)
		organization_resource = OrganizationResource.create(organization: org1, resource: resource, name: "resource1")

		@line_item = LineItem.new(request: @request, organization_resource: organization_resource, created_for: org1.organization_users.first)
    @number = TwilioNumber.default_number
	end

	should belong_to :request
  should have_one(:requesting_organization).through(:request)
	should belong_to :organization_resource
  should have_one(:resource).through(:organization_resource)
  should have_one(:requested_organization).through(:organization_resource)
	should have_many :broadcasts
  should have_many :mappings
	should have_many :phone_mappings
  should belong_to :last_edited

  should validate_presence_of :request
	should validate_presence_of :organization_resource
  should validate_presence_of :created_for

	test "it should populate non present values from its parent request" do 
		@line_item.save

    %i(earliest_start ideal_start finish_by length description location offer comment).each do |attr|
      assert_equal @request.send(attr), @line_item.send(attr)
    end
	end

	test "it should keep Overridden values" do 
		@line_item.description = "Overridden description"
		@line_item.save

		assert_not_equal @line_item.description, @request.description
		assert_equal "Overridden description", @line_item.description
  end

  #When no description: <org-user.name>: <length> at <location> with <org-resource.name> on <date> between <start>-<finish> offering <offer> URL
  test 'to_sentence should ignore the description if not present' do
    @line_item.earliest_start = Date.new
    @line_item.finish_by = Date.new
    @line_item.offer = '$25'
    @line_item.location = 'a location'
    @line_item.length = '1:00'

    @line_item.description = nil

    assert_equal 'user: 1:00 at a location with resource1 from org1 on 1/1 between 12-12am offering $25', @line_item.to_sentence
  end

  #When no description and no <length>: <org-user.name>: time at <location> with <org-resource.name> on <date> between <start>-<finish> offering <offer> URL
  test 'to_sentence should ignore the description and length if they are not present' do
    @line_item.earliest_start = Date.new
    @line_item.finish_by = Date.new
    @line_item.offer = '$25'
    @line_item.location = 'a location'
    @line_item.description = nil
    @line_item.length = nil

    assert_equal "user: time at a location with resource1 from org1 on 1/1 between 12-12am offering $25", @line_item.to_sentence
  end

  test 'to_sentence should ignore the offer if not present' do
    @line_item.earliest_start = Date.new
    @line_item.finish_by = Date.new
    @line_item.location = 'a location'
    @line_item.description = nil
    @line_item.length = nil
    @line_item.offer = nil

    assert_equal "user: time at a location with resource1 from org1 on 1/1 between 12-12am", @line_item.to_sentence
  end

  test 'to_sentence should include ideal_start if present' do
    @line_item.earliest_start = Time.parse('10 Jan 2014 02:00:00 PM UTC')
    @line_item.finish_by =  Time.parse('10 Jan 2014 04:00:00 PM UTC')
    @line_item.ideal_start =  Time.parse('10 Jan 2014 03:00:00 PM UTC')
    @line_item.location = 'a location'
    @line_item.description = nil
    @line_item.length = nil
    @line_item.offer = '$400'

    assert_equal "user: time at a location with resource1 from org1 on 1/10 between 2-4pm (ideally 3pm) offering $400", @line_item.to_sentence
  end


  test 'to_sentence should ignore the comment if not present' do
    assert_equal "user: time with resource1 from org1", @line_item.to_sentence
  end


  test 'to_sentence should include the comment if present' do
    @line_item.comment = "this is a comment"
    assert_equal "user: time with resource1 from org1 - this is a comment", @line_item.to_sentence
  end


  test 'create_opening_broadcast should create a broadcast with the author given' do
    @line_item.stubs(:to_sentence).returns('hardcoded message')
    @line_item.save(validate: false)
    Broadcast.any_instance.stubs(:send_messages)
    assert_difference 'Broadcast.count' do
      broadcast = @line_item.create_opening_broadcast(@user)
      assert_equal @user, broadcast.author
      assert_equal 'hardcoded message', broadcast.body
    end
  end

  test 'create_opening_broadcast should not add the status to the broadcast body' do
    @line_item.stubs(:to_sentence).returns('hardcoded message')
    @line_item.save(validate: false)
    Broadcast.any_instance.stubs(:send_messages)

    @line_item.expects(:body_with_status).never
    @line_item.create_opening_broadcast(@user)
  end

  test 'voice_number should delegate to the author if the user given is the receiver' do
    receiver = User.new
    author = User.new
    @line_item.stubs(:receiver).returns(receiver)
    @line_item.stubs(:author).returns(author)
    author.expects(:voice_number)
    @line_item.voice_number(receiver)
  end

  test 'voice_number should delegate to the receiver if the user given is the author' do
    receiver = User.new
    author = User.new
    @line_item.stubs(:receiver).returns(receiver)
    @line_item.stubs(:author).returns(author)
    receiver.expects(:voice_number)
    @line_item.voice_number(author)
  end

  test 'voice_number should return nil if the given user is neither the author nor the receiver' do
    receiver = User.new
    author = User.new
    @line_item.stubs(:receiver).returns(receiver)
    @line_item.stubs(:author).returns(author)
    assert_nil @line_item.voice_number(User.new)
  end

  test 'it should call reopen_request before saving' do
    @line_item.expects(:reopen_request)
    @line_item.save
  end

  test 'open scope should exclude agreed, closed or deleted line items' do
    lis = [
      LineItem.new(status: LineItemState::OFFERED),
      LineItem.new(status: LineItemState::COUNTERED),
      LineItem.new(status: LineItemState::ACCEPTED),
      LineItem.new(status: LineItemState::CLOSED),
      LineItem.new(status: LineItemState::DELETED)
    ]
    lis.each do |li|
      li.stubs(:populate_from_parent)
      li.save!(validate: false)
    end
    assert_equal lis[0..1], LineItem.open.to_a
  end

  test 'close should do nothing if it is already closed' do
    @line_item.update!(status: LineItemState::CLOSED)
    @line_item.expects(:update_last_edited).never
    @line_item.expects(:change_status).never
    @line_item.expects(:create_custom_broadcast).never
    @line_item.request.expects(:close).never
    @line_item.close(broadcast_sender: @user)
  end

  test 'close should set the status to closed' do
    @line_item.save(validate: false)
    assert !@line_item.closed?
    @line_item.close(broadcast_sender: @user)
    assert @line_item.closed?
  end

  test 'close should set last_edited_id to the OrganizationUser of the broadcast_sender given' do
    @line_item.save(validate: false)
    @line_item.update!(last_edited_id: nil)
    @line_item.close(broadcast_sender: @user)
    assert_equal @user.organization_user_for(@line_item.requesting_organization.id), @line_item.last_edited
  end

  test 'close should not change last_edited_it if a broadcast_sender is not given' do
    @line_item.save(validate: false)
    @line_item.update!(last_edited_id: nil)
    @line_item.close
    assert_nil @line_item.last_edited
  end

  test 'close should create a custom broadcast with the closing message given if a broadcast sender is given' do
    @line_item.save(validate: false)
    @line_item.expects(:create_custom_broadcast).with(@user, 'some message')
    @line_item.close(broadcast_sender: @user, closing_message: 'some message')
  end

  test 'close should not create a custom broadcast if a broadcast sender is not given' do
    @line_item.save(validate: false)
    @line_item.expects(:create_custom_broadcast).never
    @line_item.close(closing_message: 'some message')
  end

  test 'close should close the parent request if it is the last open line item and close_request is true' do
    @line_item.save(validate: false)
    assert_equal 1, @line_item.request.line_items.open.count
    @line_item.request.expects(:close).with(broadcast_sender: @user)
    @line_item.close(broadcast_sender: @user, close_request: true)
  end

  test 'close should not close the parent request if there are open line items' do
    @line_item.save(validate: false)
    open_li = LineItem.new(request: @line_item.request)
    open_li.stubs(:populate_from_parent)
    open_li.save(validate: false)
    assert_equal 2, @line_item.request.line_items.open.count
    @line_item.request.expects(:close).never
    @line_item.close(broadcast_sender: @user, close_request: true)
    assert_equal 1, @line_item.request.line_items.open.count
  end

  test 'close should not close the parent request if close_request is false' do
    @line_item.save(validate: false)
    @line_item.request.expects(:close).never
    @line_item.close(broadcast_sender: @user, close_request: false)
  end

  test 'close should close its mappings' do
    m1 = PhoneMapping.new(entity: @line_item)
    m2 = Mapping.new(entity: @line_item)
    m1.expects(:close)
    m2.expects(:close)
    @line_item.mappings = [m1, m2]
    @line_item.close
  end

  test 'offered? should return true if the status is offered' do
    @line_item.status = LineItemState::OFFERED
    assert @line_item.offered?
  end

  test 'offered? should return false if the status is not offered' do
    @line_item.status = LineItemState::ACCEPTED
    assert !@line_item.offered?
  end

  test 'countered? should return true if the status is countered' do
    @line_item.status = LineItemState::COUNTERED
    assert @line_item.countered?
  end

  test 'countered? should return false if the status is not countered' do
    @line_item.status = LineItemState::OFFERED
    assert !@line_item.countered?
  end

  test 'closed? should return true if the status is closed' do
    @line_item.status = LineItemState::CLOSED
    assert @line_item.closed?
  end

  test 'closed? should return false if the status is not closed' do
    @line_item.status = LineItemState::ACCEPTED
    assert !@line_item.closed?
  end

  test 'accepted? should return true if the status is accepted' do
    @line_item.status = LineItemState::ACCEPTED
    assert @line_item.accepted?
  end

  test 'accepted? should return false if the status is not accepted' do
    @line_item.status = LineItemState::CLOSED
    assert !@line_item.accepted?
  end

  test 'reopenable_by? should return true if it is closed and the user given belongs to the requesting organization' do
    @line_item.save(validate: false)
    @line_item.stubs(:closed?).returns(true)
    assert @line_item.requesting_organization.has_user?(@user)
    assert @line_item.reopenable_by?(@user)
  end

  test 'reopenable_by? should return false if it is not closed' do
    @line_item.save(validate: false)
    @line_item.stubs(:closed?).returns(false)
    assert !@line_item.reopenable_by?(@user)
  end

  test 'reopenable_by? should return false if the user given does not belong to the requesting organization' do
    @line_item.save(validate: false)
    @line_item.stubs(:closed?).returns(true)
    user = User.new
    assert !@line_item.requesting_organization.has_user?(user)
    assert !@line_item.reopenable_by?(user)
  end

  test 'declinable_by? should return true if it is not accepted and the given user is not the one who changed it last' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(false)
    @line_item.stubs(:last_changed_by?).with(@user).returns(false)
    assert @line_item.declinable_by?(@user)
  end

  test 'declinable_by? should return false if it is accepted' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(true)
    @line_item.stubs(:last_changed_by?).with(@user).returns(false)
    assert !@line_item.declinable_by?(@user)
  end

  test 'declinable_by? should return false if the given user is the one who changed it last' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(false)
    @line_item.stubs(:last_changed_by?).with(@user).returns(true)
    assert !@line_item.declinable_by?(@user)
  end

  test 'offerable_by? should return true if it is accepted' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(true)
    @line_item.stubs(:offered?).returns(false)
    @line_item.stubs(:last_changed_by?).with(@user).returns(false)
    assert @line_item.offerable_by?(@user)
  end

  test 'offerable_by? should return true if it is offered and the given user is the one who changed it last' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(false)
    @line_item.stubs(:offered?).returns(true)
    @line_item.stubs(:last_changed_by?).with(@user).returns(true)
    assert @line_item.offerable_by?(@user)
  end

  test 'offerable_by? should return false if it is neither accepted or offered' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(false)
    @line_item.stubs(:offered?).returns(false)
    @line_item.stubs(:last_changed_by?).with(@user).returns(true)
    assert !@line_item.offerable_by?(@user)
  end

  test 'offerable_by? should return false if it is not accepted and the given user is not the one who changed it last' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(false)
    @line_item.stubs(:offered?).returns(true)
    @line_item.stubs(:last_changed_by?).with(@user).returns(false)
    assert !@line_item.offerable_by?(@user)
  end

  test 'acceptable_by? should return true if it is accepted' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(true)
    @line_item.stubs(:last_changed_by?).with(@user).returns(true)
    assert @line_item.acceptable_by?(@user)
  end

  test 'acceptable_by? should return true if the given user is not the one who changed it last' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(false)
    @line_item.stubs(:last_changed_by?).with(@user).returns(false)
    assert @line_item.acceptable_by?(@user)
  end

  test 'acceptable_by? should return false if it is not accepted and the given user is the one who changed it last' do
    @line_item.save(validate: false)
    @line_item.stubs(:accepted?).returns(false)
    @line_item.stubs(:last_changed_by?).with(@user).returns(true)
    assert !@line_item.acceptable_by?(@user)
  end

  test 'new_status_on_update! should change the status to offered if it is closed' do
    @line_item.save(validate: false)
    @line_item.expects(:closed?).returns(true)
    @line_item.expects(:change_status).with(:offered)
    @line_item.new_status_on_update!(@user)
  end

  test 'new_status_on_update! should change the status to offered if it is accepted and the changes require confirmation' do
    @line_item.save(validate: false)
    @line_item.expects(:accepted?).returns(true)
    @line_item.expects(:update_requires_confirmation?).returns(true)
    @line_item.expects(:change_status).with(:offered)
    @line_item.new_status_on_update!(@user)
  end

  test 'new_status_on_update! should not change the status if it is accepted and the changes do not require confirmation' do
    @line_item.save(validate: false)
    @line_item.expects(:accepted?).returns(true)
    @line_item.expects(:update_requires_confirmation?).returns(false)
    @line_item.expects(:change_status).never
    @line_item.new_status_on_update!(@user)
  end

  test 'new_status_on_update! should not change the status if it is neither closed or accepted and the user given is the one who made the last change' do
    @line_item.save(validate: false)
    @line_item.expects(:closed?).returns(false)
    @line_item.expects(:accepted?).returns(false)
    @line_item.expects(:last_changed_by?).with(@user).returns(true)
    @line_item.expects(:change_status).never
    @line_item.new_status_on_update!(@user)
  end

  test 'new_status_on_update! should change the status to countered if it is neither closed or accepted, the user given is not the one who made the last change and the changes require confirmation' do
    @line_item.save(validate: false)
    @line_item.expects(:closed?).returns(false)
    @line_item.expects(:accepted?).returns(false)
    @line_item.expects(:last_changed_by?).with(@user).returns(false)
    @line_item.expects(:update_requires_confirmation?).returns(true)
    @line_item.expects(:change_status).with(:countered)
    @line_item.new_status_on_update!(@user)
  end

  test 'new_status_on_update! should change the status to accepted if it is neither closed or accepted, the user given is not the one who made the last change and the changes do not require confirmation' do
    @line_item.save(validate: false)
    @line_item.expects(:closed?).returns(false)
    @line_item.expects(:accepted?).returns(false)
    @line_item.expects(:last_changed_by?).with(@user).returns(false)
    @line_item.expects(:update_requires_confirmation?).returns(false)
    @line_item.expects(:change_status).with(:accepted)
    @line_item.new_status_on_update!(@user)
  end

  test 'body_with_status should return the text given with the status appended' do
    @line_item.expects(:humanized_status).returns('status')
    assert_equal '[status] body', @line_item.body_with_status('body')
  end

  test 'update_last_edited should set last_edited to the OrganizationUser for the given user and the requesting organization if the user belongs to the requesting organization' do
    @line_item.last_edited_id = nil
    @line_item.save(validate: false)
    @user.stubs(:is_a_requester_of_line_item?).returns(true)
    @line_item.update_last_edited(@user)
    assert_equal @line_item.last_edited, @user.organization_user_for(@line_item.requesting_organization.id)
  end

  test 'update_last_edited should set last_edited to the OrganizationUser for the given user and the requested organization if the user does not belong to the requesting organization' do
    @line_item.last_edited_id = nil
    @line_item.save(validate: false)
    @user.stubs(:is_a_requester_of_line_item?).returns(false)
    @line_item.requested_organization.add_user(@user)
    @line_item.update_last_edited(@user)
    assert_equal @line_item.last_edited, @user.organization_user_for(@line_item.requested_organization.id)
  end

  test 'reopen_request should reopen the parent request if the line item is offered and was closed' do
    @line_item.expects(:offered?).returns(true)
    @line_item.expects(:was_closed?).returns(true)
    @line_item.request.expects(:reopen)
    @line_item.send(:reopen_request)
  end

  test 'reopen_request should do nothing if the line item is not offered' do
    @line_item.expects(:offered?).returns(false)
    @line_item.stubs(:was_closed?).returns(true)
    @line_item.request.expects(:reopen).never
    @line_item.send(:reopen_request)
  end

  test 'reopen_request should do nothing if the line item was not closed' do
    @line_item.stubs(:offered?).returns(true)
    @line_item.expects(:was_closed?).returns(false)
    @line_item.request.expects(:reopen).never
    @line_item.send(:reopen_request)
  end

  test 'was_closed should return true if the previous status was closed' do
    @line_item.status = LineItemState::CLOSED
    @line_item.save(validate: false)
    @line_item.status = LineItemState::OFFERED
    assert_equal LineItemState::CLOSED, @line_item.status_was
    assert @line_item.send(:was_closed?)
  end

  test 'was_closed should return true if the previous status was not closed' do
    @line_item.status = LineItemState::OFFERED
    @line_item.save(validate: false)
    @line_item.status = LineItemState::CLOSED
    assert_equal LineItemState::OFFERED, @line_item.status_was
    assert !@line_item.send(:was_closed?)
  end

  test 'last_changed_by? should return true if the user given shares organization with the last_edited OrganizationUser' do
    user2 = create_user(name: 'u2', uniqueid: 'n2')
    @line_item.requesting_organization.add_user(user2)
    @line_item.expects(:last_edited).returns(@user.organization_user_for(@line_item.requesting_organization.id))
    assert @line_item.send(:last_changed_by?, user2)
  end

  test 'last_changed_by? should return false if the user given does not share organization with the last_edited OrganizationUser' do
    user2 = create_user(uniqueid: 'n2')
    @line_item.expects(:last_edited).returns(@user.organization_user_for(@line_item.requesting_organization.id))
    assert !@line_item.send(:last_changed_by?, user2)
  end

  test 'update_requires_confirmation? should return true if the time window has been broaded' do
    @line_item.expects(:time_window_broadened?).returns(true)
    assert @line_item.send(:update_requires_confirmation?)
  end

  test 'update_requires_confirmation? should return true if at least one field that was previously not null has been changed' do
    @line_item.location = 'l'
    @line_item.save(validate: false)
    @line_item.stubs(:time_window_broadened?).returns(false)
    assert !@line_item.send(:update_requires_confirmation?)
    @line_item.location = 'location'
    assert @line_item.send(:update_requires_confirmation?)
  end

  test 'update_requires_confirmation? should return false if the time window has not been broaded and there is no changed field that was previously not null' do
    @line_item.save(validate: false)
    @line_item.location = nil
    @line_item.save(validate: false)
    @line_item.stubs(:time_window_broadened?).returns(false)
    @line_item.location = 'location'
    assert !@line_item.send(:update_requires_confirmation?)
  end

  test 'time_window_broadened? should return true if earliest_start was not null and has been moved backwards' do
    @line_item.save(validate: false)
    @line_item.earliest_start = Time.now
    @line_item.save(validate: false)
    @line_item.earliest_start = @line_item.earliest_start - 10.minutes
    assert @line_item.send(:time_window_broadened?)
  end

  test 'time_window_broadened? should return true if earliest_start was not null and has been cleared' do
    @line_item.save(validate: false)
    @line_item.earliest_start = Time.now
    @line_item.save(validate: false)
    @line_item.earliest_start = nil
    assert @line_item.send(:time_window_broadened?)
  end

  test 'time_window_broadened? should return true if finish_by was not null and has been moved forward' do
    @line_item.save(validate: false)
    @line_item.finish_by  = Time.now
    @line_item.save(validate: false)
    @line_item.finish_by  = @line_item.finish_by + 10.minutes
    assert @line_item.send(:time_window_broadened?)
  end

  test 'time_window_broadened? should return true if finish_by was not null and has been cleared' do
    @line_item.save(validate: false)
    @line_item.finish_by = Time.now
    @line_item.save(validate: false)
    @line_item.finish_by = nil
    assert @line_item.send(:time_window_broadened?)
  end

  test 'time_window_broadened? should return false if earliest_start and finish_by were null' do
    @line_item.save(validate: false)
    @line_item.earliest_start = nil
    @line_item.finish_by = nil
    @line_item.save(validate: false)
    @line_item.earliest_start = Time.now
    @line_item.finish_by = Time.now
    assert !@line_item.send(:time_window_broadened?)
  end

  test 'time_window_broadened? should return false if earliest_start has been moved forward and finish_by backward' do
    @line_item.save(validate: false)
    @line_item.earliest_start = Time.now
    @line_item.finish_by = Time.now
    @line_item.save(validate: false)
    @line_item.earliest_start = @line_item.earliest_start + 10.minutes
    @line_item.finish_by = @line_item.finish_by - 10.minutes
    assert !@line_item.send(:time_window_broadened?)
  end

  test 'create_custom_broadcast should create a broadcast with the message given as parameter' do
    @line_item.stubs(:body_with_status).with('some body to love').returns('[status] body')
    Broadcast.expects(:create_with_user).with(broadcastable: @line_item, user: @user, body: '[status] body')
    @line_item.send(:create_custom_broadcast, @user, 'some body to love')
  end

  test 'receiver_mapping should return an active phone mapping of its receiver' do
    @line_item.save(validate: false)

    PhoneMapping.create!(status: MappingState::CLOSED, entity: @line_item, user: @line_item.receiver, twilio_number: TwilioNumber.first)
    assert_nil @line_item.receiver_mapping
    m = PhoneMapping.new(entity: @line_item, user: @line_item.receiver, twilio_number: TwilioNumber.first)
    m.save!(validate: false)
    assert_equal m, @line_item.receiver_mapping
  end

  test 'author_mapping should return an active phone mapping of the author of its request' do
    @line_item.save(validate: false)

    PhoneMapping.create!(status: MappingState::CLOSED, entity: @line_item, user: @user, twilio_number: TwilioNumber.first)
    assert_nil @line_item.author_mapping
    m = PhoneMapping.new(entity: @line_item, user: @user, twilio_number: TwilioNumber.first)
    m.save!(validate: false)
    assert_equal m, @line_item.author_mapping
  end

  test 'resource_full_name should return the full_name of the target organization_resource' do
    org_resource = OrganizationResource.new
    org_resource.expects(:full_name)
    @line_item.expects(:target_org_resource).with(@user).returns(org_resource)
    @line_item.resource_full_name(@user)
  end

  test 'caller_info should return a caller with the reserved number for its request if the user given is the requesting user and the request is unbranded' do
    @line_item.expects(:requesting_user?).with(@user).returns(true)
    @line_item.request.expects(:reserved_number).twice.returns(@number)
    assert_equal Caller.new(@number, nil), @line_item.caller_info(@user)
  end

  test 'caller_info should return a caller with the twilio number of the requested mapping if the user given is the requesting user and the request is branded' do
    @line_item.expects(:requesting_user?).with(@user).returns(true)
    mapping_number = TwilioNumber.create!(number: '1234567890')
    @line_item.expects(:receiver_mapping).returns(PhoneMapping.new(twilio_number: mapping_number))
    @line_item.request.expects(:reserved_number).returns(nil)
    assert_equal Caller.new(mapping_number, @line_item.organization_resource, @line_item.requesting_organization.org_user_for(@user)), @line_item.caller_info(@user)
  end

  test 'caller_info should return a caller with the twilio number of the requesting mapping if the user given is not the requesting user' do
    @line_item.expects(:requesting_user?).with(@user).returns(false)
    mapping_number = TwilioNumber.create!(number: '1234567890')
    @line_item.expects(:author_mapping).returns(PhoneMapping.new(twilio_number: mapping_number))
    assert_equal Caller.new(mapping_number, @line_item.organization_resource, @line_item.requested_organization.org_user_for(@user)), @line_item.caller_info(@user)
  end

  test 'author should delegate to request' do
    @line_item.request.expects(:author)
    @line_item.author
  end

  test 'created_by should delegate to request' do
    @line_item.request.expects(:created_by)
    @line_item.created_by
  end

  test 'edited_by_name should return the full_name of the last_edited' do
    ou = OrganizationUser.new
    ou.expects(:full_name).returns('something')
    @line_item.expects(:last_edited).twice.returns(ou)
    assert_equal 'something', @line_item.edited_by_name
  end

  test 'edited_by_name should return - if there is no last_edited' do
    assert_nil @line_item.last_edited
    assert_equal '-', @line_item.edited_by_name
  end

  test 'created_by_name should return the full_name of the request created_by' do
    ou = OrganizationUser.new
    ou.expects(:full_name).returns('something')
    @line_item.request.expects(:created_by).returns(ou)
    assert_equal 'something', @line_item.created_by_name
  end

  test 'receiver should return the user of its created_for' do
    assert_equal @line_item.created_for.user, @line_item.receiver
  end

  test 'update_receiver should find or create a user by the denormalized phone given' do
    User.expects(:find_or_create_user).with( { voice: '13459876543', sms: '13459876543'}, '(345) 987-6543', default_org_resource: @line_item.organization_resource, without_org: true).returns(User.first)
    @line_item.update_receiver('13459876543')
  end

  test 'update_receiver should add the user fetched to the requested organization' do
    u2 = create_user(name: 'u2', uniqueid: 'u2')
    User.expects(:find_or_create_user).returns(u2)
    assert_difference '@line_item.requested_organization.users.count' do
      @line_item.update_receiver('13459876543')
      @line_item.requested_organization.organization_users.last.tap do |created_ou|
        assert_equal u2, created_ou.user
        assert_equal OrganizationUserState::UNTRUSTED, created_ou.status
      end
    end
  end

  test 'update_receiver should update its created_for to the organization user created' do
    u2 = create_user(name: 'u2', uniqueid: 'u2')
    User.expects(:find_or_create_user).returns(u2)
    assert_equal @line_item.requested_organization.organization_users.first, @line_item.created_for
    @line_item.update_receiver('13459876543')
    assert_equal u2, @line_item.created_for.user
  end

  test 'change_receiver should update created_for to the organization user that matchs the requested organization and the user given' do
    new_receiver = create_user(name: 'receiver', uniqueid: 'receiver')
    new_created_for = @line_item.requested_organization.add_user(new_receiver)
    assert_not_equal new_created_for, @line_item.created_for
    @line_item.change_receiver(new_receiver)
    assert_equal new_created_for, @line_item.created_for
  end

  test 'it should call create_missing_mappings after_save if created_for changed' do
    @line_item.save!(validate: false)

    new_created_for = OrganizationUser.new
    new_created_for.save!(validate: false)
    assert_not_equal new_created_for, @line_item.created_for
    @line_item.created_for = new_created_for
    @line_item.expects(:create_missing_mappings)
    @line_item.save!(validate: false)
  end

  test 'it should not call create_missing_mappings after_save if created_for has not changed' do
    @line_item.save!(validate: false)
    @line_item.offer = 'something else'
    @line_item.expects(:create_missing_mappings).never
    @line_item.save!(validate: false)
  end

  test 'create_missing_mappings should call create_mappings on its receiver' do
    @line_item.receiver.expects(:create_mappings)
    @line_item.send :create_missing_mappings
  end

  test 'requesting_user? should return true if the user given belongs to the requesting organization' do
    assert @line_item.requesting_organization.has_user?(@user)
    assert @line_item.requesting_user?(@user)
  end

  test 'requesting_user? should return false if the user given does not belong to the requesting organization' do
    u = create_user
    assert !@line_item.requesting_organization.has_user?(u)
    assert !@line_item.requesting_user?(u)
  end

  test 'requested_user? should return true if the user given belongs to the requested organization' do
    u = create_user
    @line_item.requested_organization.add_user(u)
    assert @line_item.requested_organization.has_user?(u)
    assert @line_item.requested_user?(u)
  end

  test 'requested_user? should return false if the user given does not belong to the requested organization' do
    u = create_user
    assert !@line_item.requested_organization.has_user?(u)
    assert !@line_item.requested_user?(u)
  end

  test 'requesting_organization_user should return the organization user related to the requesting organization and the user given' do
    u = create_user
    ou = @line_item.requesting_organization.add_user(u)
    assert_equal ou, @line_item.requesting_organization_user(u)
  end

  test 'requesting_organization_user should return nil if there is no organization user related to the requesting organization and the user given' do
    assert_nil @line_item.requesting_organization_user(create_user)
  end

  test 'requested_organization_user should return the organization user related to the requested organization and the user given' do
    u = create_user
    ou = @line_item.requested_organization.add_user(u)
    assert_equal ou, @line_item.requested_organization_user(u)
  end

  test 'requested_organization_user should return nil if there is no organization user related to the requested organization and the user given' do
    assert_nil @line_item.requested_organization_user(create_user)
  end

  test 'organization_user_for should return the organization user related to the requesting organization and the user given' do
    u = create_user
    ou = @line_item.requesting_organization.add_user(u)
    assert_equal ou, @line_item.organization_user_for(u)
  end

  test 'organization_user_for should return the organization user related to the requested organization and the user given if there is no organization user that matches the requesting org and the user' do
    u = create_user
    ou = @line_item.requested_organization.add_user(u)
    assert !@line_item.requesting_organization.has_user?(u)
    assert_equal ou, @line_item.organization_user_for(u)
  end

  test 'receiver_contacts should return the notifiable contacts of the receiver allowing unverified ones' do
    @line_item.receiver.expects(:notifiable_contacts).with(allow_unverified: true)
    @line_item.receiver_contacts
  end

  test 'author contacts should return the notifiable contacts' do
    @line_item.author.expects(:notifiable_contacts)
    @line_item.author_contacts
  end

  test 'mail_prefix should return the uniqueid of the requesting organization if the user given belongs to the requested organization' do
    u = create_user
    @line_item.requested_organization.add_user(u)
    assert_equal @line_item.requesting_organization.uniqueid, @line_item.mail_prefix(u)
  end

  test 'mail_prefix should return the uniqueid of the requested organization if the user given belongs to the requesting organization' do
    u = create_user
    @line_item.requesting_organization.add_user(u)
    assert_equal @line_item.requested_organization.uniqueid, @line_item.mail_prefix(u)
  end

  test 'mapping_path should return the url to the line item' do
    @line_item.save!(validate: false)
    assert_equal "/requests/#{ @line_item.request.id }/line_items/#{ @line_item.id }", @line_item.mapping_path
  end
end