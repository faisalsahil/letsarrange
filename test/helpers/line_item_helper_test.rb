require 'test_helper'

class LineitemHelperTest < ActionView::TestCase
  include LineItemHelper
  
  def setup
    super
    @user = create_user

    @earliest_start = Time.zone.parse('10 Jan 2014 02:00:00 PM UTC')
    @ideal_start = Time.zone.parse('10 Jan 2014 03:00:00 PM UTC')
    @finish_by = Time.zone.parse('10 Jan 2014 04:00:00 PM UTC')

    @request = Request.new earliest_start: @earliest_start, finish_by: @finish_by, ideal_start: @ideal_start,
                            length: "0:10", description: "Massage",
                            location: "my Place", offer: '$100'
                            
    @request.save(validate: false)

    @org = Organization.new name: "org", uniqueid: "org1"
    @org.save(validate: false)

    @resource = Resource.new name: "resource", uniqueid: "resource"
    @resource.save(validate: false)

    @org_resource = OrganizationResource.new name: "jose", organization: @org, resource: @resource
    @org_resource.stubs(:valid?).returns(true)
    @org_resource.save()

    @line = LineItem.new(request: @request, organization_resource: @org_resource, location: "your place", offer: '$200',
                            length: "0:20")
    @line.save(validate: false)
  end

  test "line item byline should use LineChange to generate a difference summary between the LI and it's request" do
     assert_equal "at your place for 0:20 offering $200", line_item_byline(@line)
  end
end