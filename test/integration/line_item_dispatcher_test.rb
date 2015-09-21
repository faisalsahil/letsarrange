require 'test_helper'

class LineItemDispatcherTest < ActiveSupport::TestCase
  def setup
    super
    @user = create_user

    @request = Request.new earliest_start: 1.hour.since, finish_by: 3.hours.since, ideal_start: 2.hours.since,
                            length: "0:10", description: "Massage",
                            location: "My Place", offer: '$100', organization_resource: @user.default_org_resource,
                            last_edited_id: @user.organization_users.where(organization_id: @user.default_org.id).first.id
                            
    @request.save(validate: false)

    u2 = create_user(name: 'requestee', uniqueid: 'requestee')
    org = Organization.new name: "org", uniqueid: "org1"
    org.save(validate: false)
    org.add_user(u2)

    resource = Resource.new name: "resource", uniqueid: "resource"
    resource.save(validate: false)

    @org_resource = OrganizationResource.new name: "jose", organization: org, resource: resource
    @org_resource.stubs(:valid?).returns(true)
    @org_resource.save

    @line = LineItem.new request: @request, organization_resource: @org_resource, created_for: u2.organization_users.first
    @line.save(validate: false)

    @dispatcher = LineItemDispatcher.new @line, @user
  end

  test "it should respond to dispatch" do 
    assert_respond_to @dispatcher, :dispatch
  end

  test "it should update the line item with the attributes passed" do 
   line_attributes = base_attributes
   line_attributes = line_attributes.merge({ organization_resource_id: @org_resource.id })
    
    assert_no_difference ["LineItem.count", "OrganizationResource.count"] do                                  
      line = @dispatcher.dispatch line_attributes
    
      assert_equal "2014-02-06 7:55", line.earliest_start.strftime("%Y-%m-%d %-I:%M") 
      assert_equal "2014-02-06 8:55", line.ideal_start.strftime("%Y-%m-%d %-I:%M") 
      assert_equal "2014-02-06 9:55", line.finish_by.strftime("%Y-%m-%d %-I:%M") 
      assert_equal "0:20", line.length
      assert_equal "Lesson", line.description
      assert_equal "My Place", line.location
      assert_equal '$220', line.offer
      assert_equal @org_resource, line.organization_resource                                 
    end
  end

  test "it should create new resources" do 
    line_attributes = base_attributes
    org_resource_attributes = { organization_resource_attributes: {name: "pedro", id: @org_resource.id} }

    line_attributes = line_attributes.merge org_resource_attributes

    assert_difference ["OrganizationResource.count", "Resource.count"] do 
      line = @dispatcher.dispatch line_attributes
      assert_equal OrganizationResource.where(name: "pedro").first, line.organization_resource
    end
  end

  test "it should attach new resources to the requested org" do 
    line_attributes = base_attributes
    org_resource_attributes = { organization_resource_attributes: {name: "pedro", id: @org_resource.id} }

    line_attributes = line_attributes.merge org_resource_attributes

    line = @dispatcher.dispatch line_attributes
    resource = OrganizationResource.where(name: "pedro").first
    assert line.requested_organization.organization_resources.include? resource
  end

  test "it should generate a broadcast to all members of the org notifying them about the changes" do 
    line_attributes = base_attributes
    line_change_attributes = { line_change: {user: "alfredo", comment: "comment"}}
    line_attributes = line_attributes.merge line_change_attributes
    
    assert_difference "Broadcast.count" do
      @dispatcher.dispatch line_attributes
    end
  end

  test "it should NOT generate a broadcast to all members of the org notifying them about the changes" do 
    assert_no_difference "Broadcast.count" do
      @dispatcher.dispatch @line.attributes.merge(line_change: {})
    end
  end

  test 'dispatch should set the last_edited org-user' do 
    line = @dispatcher.dispatch base_attributes
    assert_not_nil line.last_edited
  end

  test 'dispatch should set the new status of the line item' do
    @dispatcher.instance_eval('@line').expects(:new_status_on_update!).with(@user)
    @dispatcher.dispatch(base_attributes)
  end

  test 'dispatch should set the last_edited of the line item if there are substantial changes' do
    LineChange.any_instance.expects(:substantial_changes?).returns(true)
    @dispatcher.instance_eval('@line').expects(:update_last_edited).with(@user)
    @dispatcher.dispatch(base_attributes)
  end

  test 'dispatch should not set the last_edited of the line item if there are no substantial changes' do
    LineChange.any_instance.expects(:substantial_changes?).returns(false)
    @dispatcher.instance_eval('@line').expects(:update_last_edited).never
    @dispatcher.dispatch(base_attributes)
  end

  test 'dispatch should create a broadcast if there are substantial changes' do
    LineChange.any_instance.expects(:substantial_changes?).returns(true)
    Broadcast.expects(:create_with_user)
    @dispatcher.dispatch(base_attributes)
  end

  test 'dispatch should not create a broadcast if there are no substantial changes' do
    LineChange.any_instance.expects(:substantial_changes?).returns(false)
    Broadcast.expects(:create_with_user).never
    @dispatcher.dispatch(base_attributes)
  end

  test 'dispatch should change the receiver of the line item if there are substantial changes' do
    LineChange.any_instance.expects(:substantial_changes?).returns(true)
    @line.expects(:change_receiver).with(@user)
    @dispatcher.dispatch(base_attributes)
  end

  def base_attributes
    { earliest_start: "2014-02-06 19:55:00",
      ideal_start: "2014-02-06 20:55:00", 
      finish_by: "2014-02-06 21:55:00",
      length: "0:20", description: "Lesson", 
      location: "My Place", offer: '$220',
      line_change: {}
    }
  end                              
end