require 'test_helper'

class RequestsDispatcherTest < ActiveSupport::TestCase
	def setup
    super
		@requester = create_user
    @organization_making_the_request = @requester.default_org
		@request = Request.new organization_resource: @requester.default_org_resource , earliest_start: Time.now, finish_by: (Time.now + 1.hour)

    contact_point = "15005550010"
    requestee = User.find_or_create_user( { sms: contact_point }, '(500) 555-0010', organization_name: 'org_name', resource_name: 'mike')
    resource = Resource.create name: "resource-#{ contact_point }", uniqueid: "resource-#{ contact_point }"
    organization_resource = requestee.default_org.organization_resources.create resource: resource, name: resource.name

    @line_items_attributes = { line_items_attributes: {
      "0" => { organization_resource_id: organization_resource.id, created_for_id: requestee.organization_users.first.id }
    }}

    User.any_instance.stubs(:preferred_area_code).returns('345')
	end

	test 'it should respond to dispatch' do
		assert_respond_to RequestsDispatcher, :dispatch
	end
	
	test 'dispatch should create a new request' do
		assert_difference 'Request.count' do
			request = RequestsDispatcher.dispatch @request.attributes, @requester
      assert_equal @organization_making_the_request.requests, [request]
		end
	end
	
	test 'dispatch should save any line item within the request' do
		request_attributes = @request.attributes.merge @line_items_attributes 

		assert_difference ['Request.count', 'LineItem.count'] do
		  RequestsDispatcher.dispatch(request_attributes, @requester)
		end

    assert_equal @organization_making_the_request.requests.last.line_items, [LineItem.last]
	end

	test 'dispatch should use TwilioSender to schedule and send messages' do 
    request_attributes = @request.attributes.merge @line_items_attributes 

		assert_difference ['Request.count', 'SmsMessage.count'] do
			RequestsDispatcher.dispatch(request_attributes, @requester)
		end
	end

  test 'dispatch should create broadcasts for line_items of the request' do
    request_attributes = @request.attributes.merge @line_items_attributes 

    assert_difference 'Broadcast.count' do
      RequestsDispatcher.dispatch(request_attributes, @requester)
    end
  end

  test 'dispatch should set the last_edited org-user' do 
		request = RequestsDispatcher.dispatch @request.attributes, @requester
		assert_not_nil request.last_edited
 	end

  test 'create_broadcasts should create mappings for the requesting user' do
    li = LineItem.new
    @request.stubs(:line_items).returns([li])
    @requester.expects(:create_mappings).with(li, true)
    li.stubs(:create_opening_broadcast)
    RequestsDispatcher.create_broadcasts(@request, @requester)
  end

  test 'create_broadcasts should create opening broadcasts for each line item' do
    li = LineItem.new
    @request.stubs(:line_items).returns([li])
    li.stubs(:create_mappings)
    li.expects(:create_opening_broadcast).with(@requester)
    RequestsDispatcher.create_broadcasts(@request, @requester)
  end

  test 'dispatch should assign an reserved_number to the request if it is not branded' do
    request = RequestsDispatcher.dispatch @request.attributes.merge(message_branding: MessageBrandingState::HUMANIZED), @requester
    assert_equal @organization_making_the_request.requests, [request]
    assert_equal TwilioNumber.first, request.reserved_number
  end
end