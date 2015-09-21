require 'test_helper'

class InboundNumbersControllerTest < ActionDispatch::IntegrationTest
  def setup
    super
    enable_js
    @user = fake_sign_in_user
  end

  test 'a user should be able to merge an inbound number with a line item' do
    request = Request.create!(organization_resource: @user.default_org_resource,
                              created_by: @user.organization_users.first,
                              time_zone: 'UTC',
                              earliest_start: Time.now,
                              finish_by: Time.now,
                              length: '0:00',
                              reserved_number: TwilioNumber.default_number)

    resource = Resource.new  name: "Dana", uniqueid: "dana"
    resource.save(validate: false)

    requested_user = create_user(name: 'u2', uniqueid: 'u2')

    earliest_start = Time.parse('10 Jan 2014 02:00:00 PM UTC')
    finish_by = Time.parse('10 Jan 2014 03:00:00 PM UTC')

    line_item = LineItem.create!(earliest_start: earliest_start,
                                 finish_by: finish_by,
                                 length: "1:00", description: "Massage",
                                 location: "My Place", offer: '$50',
                                 organization_resource: requested_user.default_org_resource,
                                 request: request,
                                 created_for: requested_user.organization_users.first,
                                 last_edited: @user.organization_users.first)

    inbound = InboundNumber.create!(number: '13451234567', request: request)
    created_broadcast = inbound.broadcasts.create!(body: 'im an inbound number broadcast')
    another_broadcast = inbound.broadcasts.create!(body: 'im another broadcast')
    visit request_path(request)

    assert page.has_content?('im an inbound number broadcast')
    assert page.has_content?('im another broadcast')
    within "#broadcast_#{ created_broadcast.id}" do
      select 'u2', from: 'broadcast_broadcastable_id'
      click_button 'transfer'
    end
    assert page.has_no_content?('im an inbound number broadcast')
    assert find("#line_item_#{ line_item.id }").has_content?('im another broadcast')
    visit request_line_item_path(request, line_item)
    assert page.has_content?('im an inbound number broadcast')
    assert page.has_content?('im another broadcast')
  end
end