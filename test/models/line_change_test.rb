require 'test_helper'

class LineChangeTest < ActiveSupport::TestCase
  include LineItemHelper

  def setup
    super
    @user = create_user(name: 'alfredo')

    @earliest_start = Time.parse('10 Jan 2014 02:00:00 PM UTC')
    @ideal_start = Time.parse('10 Jan 2014 02:40:00 PM UTC')
    @finish_by = Time.parse('10 Jan 2014 04:00:00 PM UTC')

    @request = Request.new earliest_start: @earliest_start, finish_by: @finish_by, ideal_start: @ideal_start,
                            length: "0:10", description: "Massage",
                            location: "My Place", offer: '$100'
                            
    @request.save(validate: false)

    @org = Organization.new name: "org", uniqueid: "org1"
    @org.save(validate: false)

    @resource = Resource.new name: "resource", uniqueid: "resource"
    @resource.save(validate: false)

    @org_resource = OrganizationResource.new name: "jose", organization: @org, resource: @resource
    @org_resource.stubs(:valid?).returns(true)
    @org_resource.save()

    @line = LineItem.new request: @request, organization_resource: @org_resource
    @line.save(validate: false)

    @change = LineChange.new(line: @line, user: @user)
  end

  test "it should respond to to_sentence" do 
    assert_respond_to @change, :to_sentence
  end

  test "to_sentence should be nil if there's no differences" do 
    assert_nil @change.to_sentence(@line)
  end

  test "to_sentence should starts with <user.name>: if there's is a difference" do 
    new_line = LineItem.new request: @request, organization_resource: @org_resource, location: "New location"
    new_line.save(validate: false)

    assert @change.to_sentence(new_line).starts_with?("alfredo:")
  end

  test "to_sentence should include with <new org-resource.name> if the org-resource was changed" do
    new_org_resource = OrganizationResource.new name: "Pepito", organization: @org, resource: @resource
    new_org_resource.stubs(:valid?).returns(true)
    new_org_resource.save()
    
    new_line = LineItem.new request: @request, organization_resource: new_org_resource
    new_line.save(validate: false)

    assert_equal "alfredo: with Pepito", @change.to_sentence(new_line)
  end

  test "to_sentence should include for <what> if the description changed" do 
    new_line = LineItem.new request: @request, organization_resource: @org_resource, description: "Lesson"
    new_line.save(validate: false)

    assert_equal "alfredo: Lesson", @change.to_sentence(new_line)
  end

  test "to_sentence should include at <where> if the location changed" do 
    new_line = LineItem.new request: @request, organization_resource: @org_resource, location: "your place"
    new_line.save(validate: false)

    assert_equal "alfredo: at your place", @change.to_sentence(new_line)
  end

  test "to_sentence should include for <length> if the length changed" do 
    new_line = LineItem.new request: @request, organization_resource: @org_resource, length: "0:20"
    new_line.save(validate: false)

    assert_equal "alfredo: for 0:20", @change.to_sentence(new_line)
  end

  test "to_sentence should include from <start> to <finish> date if earliest_start date changed" do 
    earliest_start = Time.parse('11 Jan 2014 02:00:00 PM UTC')
    new_line = LineItem.new request: @request, organization_resource: @org_resource, earliest_start: earliest_start
    new_line.save(validate: false)
    assert_equal "alfredo: on 1/11 between 2-4pm",@change.to_sentence(new_line)
  end

  test "to_sentence should include from <start> to <finish> time if earliest_start time changed" do 
    earliest_start = Time.parse('10 Jan 2014 03:00:00 PM UTC')
    new_line = LineItem.new request: @request, organization_resource: @org_resource, earliest_start: earliest_start
    new_line.save(validate: false)
    assert_equal "alfredo: on 1/10 between 3-4pm",@change.to_sentence(new_line)
  end

  test "to_sentence should include from <start> to <finish> time if finish_by time changed" do 
    finish_by = Time.parse('10 Jan 2014 06:00:00 PM UTC')
    new_line = LineItem.new request: @request, organization_resource: @org_resource, finish_by: finish_by
    new_line.save(validate: false)
    assert_equal "alfredo: on 1/10 between 2-6pm",@change.to_sentence(new_line)
  end

  test "to_sentence should include (ideally time) if ideal_start changed" do 
    ideal_start = Time.parse('10 Jan 2014 03:00:00 PM UTC')
    new_line = LineItem.new request: @request, organization_resource: @org_resource, ideal_start: ideal_start
    new_line.save(validate: false)
    assert_equal "alfredo: (ideally 3pm)",@change.to_sentence(new_line)
  end

  test "to_sentence should include offering <offer> if offer changed" do
    new_line = LineItem.new request: @request, organization_resource: @org_resource, offer: 'something'
    new_line.save(validate: false)

    assert_equal 'alfredo: offering something', @change.to_sentence(new_line)
  end

  test "to_sentence should include any additional comment at the end of the message" do 
    new_line = LineItem.new request: @request, organization_resource: @org_resource, offer: '$200'
    new_line.save(validate: false)
    @change.comment = "This rocks!"

    assert_equal "alfredo: offering $200 - This rocks!", @change.to_sentence(new_line)
  end

  test "to_sentence should generate a summary difference message" do 
    new_org_resource = OrganizationResource.new name: "Pepito", organization: @org, resource: @resource
    new_org_resource.stubs(:valid?).returns(true)
    new_org_resource.save()
    earliest_start = Time.parse('11 Jan 2014 03:00:00 PM UTC')

    new_line = LineItem.new request: @request, organization_resource: new_org_resource, offer: '$200',
                            earliest_start: earliest_start, description: "Lesson", location: "your place",
                            length: "0:20"
    new_line.save(validate: false)

    @change.comment = "This rocks!"

    assert_equal "alfredo: Lesson at your place with Pepito for 0:20 on 1/11 between 3-4pm offering $200 - This rocks!",
                    @change.to_sentence(new_line)
  end

  test "to_sentence should add (removed how long) if length is cleared" do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    new_line.length = nil 
    assert_equal "alfredo: (removed how long)",@change.to_sentence(new_line)
  end

  test "to_sentence should add (removed ideal start) if ideal_start is cleared" do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    new_line.ideal_start = nil
    assert_equal "alfredo: (removed ideal start)",@change.to_sentence(new_line)
  end

  test "to_sentence should add (removed start and finish) if start and finish are cleared" do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    new_line.earliest_start = nil
    new_line.finish_by = nil
    assert_equal "alfredo: (removed start and finish)",@change.to_sentence(new_line)
  end

  test "to_sentence should NOT add (removed start and finish) if line.start and line.finish are nil too" do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    new_line.earliest_start = nil
    new_line.finish_by = nil
    @line.finish_by = nil
    @line.earliest_start = nil 

    assert_nil @change.to_sentence(new_line)
  end

  test "to_sentence should add (removed offer) if offer is cleared" do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    new_line.offer = nil
    assert_equal "alfredo: (removed offer)",@change.to_sentence(new_line)
  end

  test "to_sentence should add (removed where) if where is cleared" do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    new_line.location = nil 
    assert_equal "alfredo: (removed where)",@change.to_sentence(new_line)
  end

  test "to_sentence should add (removed for what) if what is cleared" do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    new_line.description = nil 
    assert_equal "alfredo: (removed for what)",@change.to_sentence(new_line)
  end

  test 'to_sentence should add [status] if with_status is truthy and the status has changed' do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    @change.expects(:status_changed?).with(new_line).returns(true)
    new_line.expects(:humanized_status).returns('offered')
    assert_equal '[offered] alfredo:', @change.to_sentence(new_line, with_status: true)
  end

  test 'to_sentence should add the formated ideal date if show_ideal_start? returns true' do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    @change.expects(:show_ideal_start?).with(new_line).returns(true)
    IdealLineItemText.any_instance.expects(:to_sentence)
    @change.to_sentence(new_line, with_status: true)
  end

  test 'to_sentence should not add the formated ideal date if show_ideal_start? returns false' do
    new_line = LineItem.new request: @request, organization_resource: @org_resource
    new_line.save(validate: false)
    @change.expects(:show_ideal_start?).with(new_line).returns(false)
    IdealLineItemText.any_instance.expects(:to_sentence).never
    @change.to_sentence(new_line, with_status: true)
  end

  test 'substantial_changes? returns true if a comment is present' do
    @change = LineChange.new(line: @line, user: @user, comment: 'some comment')
    @change.stubs(:fields_changed?).returns(false)
    new_line = LineItem.new(request: @request, organization_resource: @org_resource)
    new_line.save(validate: false)
    assert @change.substantial_changes?(new_line)
  end

  test 'substantial_changes? returns true if at least one field changed' do
    @change = LineChange.new(line: @line, user: @user)
    @change.expects(:fields_changed?).returns(true)
    new_line = LineItem.new(request: @request, organization_resource: @org_resource)
    new_line.save(validate: false)
    assert @change.substantial_changes?(new_line)
  end

  test 'status_changed? should return true if the status changed' do
    new_line = LineItem.new(status: LineItemState::CLOSED)
    assert @change.send(:status_changed?, new_line)
  end

  test 'status_changed? should return false if the status has not changed' do
    new_line = LineItem.new(status: @line.status)
    assert !@change.send(:status_changed?, new_line)
  end

  test 'show_ideal_start? should return true if the ideal start has changed' do
    new_line = LineItem.new(ideal_start: @line.ideal_start + 2.hours)
    assert @change.send(:show_ideal_start?, new_line)
  end

  test 'show_ideal_start? should return true if the line item has just been accepted' do
    @line.status = LineItemState::OFFERED
    @line.save(validate: false)
    new_line = LineItem.new(ideal_start: @line.ideal_start, status: LineItemState::ACCEPTED)
    assert @change.send(:show_ideal_start?, new_line)
  end

  test 'show_ideal_start? should return false otherwise' do
    @line.status = LineItemState::OFFERED
    @line.save(validate: false)
    new_line = LineItem.new(ideal_start: @line.ideal_start, status: LineItemState::OFFERED)
    assert !@change.send(:show_ideal_start?, new_line)
  end

  test 'fields_changed? should return true if at least one attribute has changed' do
    new_line = LineItem.new(request: @request, organization_resource: @org_resource)
    new_line.send(:populate_from_parent)
    new_line.ideal_start = @line.ideal_start + 2.hours
    assert @change.send(:fields_changed?, new_line)
  end

  test 'fields_changed? should return false if none attribute has changed' do
    new_line = LineItem.new(request: @request, organization_resource: @org_resource)
    new_line.send(:populate_from_parent)
    assert !@change.send(:fields_changed?, new_line)
  end
end