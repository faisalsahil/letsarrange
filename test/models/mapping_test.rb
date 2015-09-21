require 'test_helper'

class MappingTest < ActiveSupport::TestCase
  def setup
    super
    request = Request.new time_zone: "Buenos Aires", earliest_start: Time.now, finish_by: Time.now
    request.save(validate: false)

    @line_item1 = LineItem.new request: request
    @line_item1.stubs(:populate_from_parent).returns(true)
    @line_item1.save(validate: false)
    @line_item2 = LineItem.new request: request
    @line_item2.stubs(:populate_from_parent).returns(true)
    @line_item2.save(validate: false)

    @user = create_user

    PhoneMapping.any_instance.stubs(:generate_code)
    Mapping.any_instance.stubs(:generate_code)
  end

  should validate_presence_of :entity
  should validate_presence_of :user
  should validate_uniqueness_of :user_id

  should belong_to :entity
  should belong_to :user

  test 'for_entity scope should find the mappings that point to a given entity' do
    m = PhoneMapping.new(entity: @line_item1)
    m.save(validate: false)
    PhoneMapping.new(entity: @line_item2).save(validate: false)
    assert_equal [m], Mapping.for_entity(@line_item1)
  end

  test 'it should validate that entity_type is one of LineItem, InboundNumber' do
    assert Mapping.new(user: @user, entity: @line_item1).valid?
    assert Mapping.new(user: @user, entity: InboundNumber.create!(number: '12345', request: @line_item1.request)).valid?
    assert Mapping.new(user: @user, entity: User.first).invalid?
  end

  test 'line_item should return entity' do
    m = Mapping.new(user: @user, entity: @line_item1)
    assert_equal @line_item1, m.line_item
  end

  test 'inbound_number should return entity' do
    m = Mapping.new(user: @user, entity: @line_item1)
    assert_equal @line_item1, m.inbound_number
  end

  test 'close should change the status to closed' do
    m = Mapping.new
    m.expects(:change_status).with(:closed)
    m.close
  end

  test 'mapping_for should return the first active mapping for the given user and entity' do
    u2 = create_user(name: 'u2', uniqueid: 'u2')
    Mapping.delete_all
    PhoneMapping.create!(user: @user, entity: @line_item1, twilio_number: TwilioNumber.first, status: MappingState::CLOSED)
    PhoneMapping.create!(user: @user, entity: @line_item2, twilio_number: TwilioNumber.first)
    PhoneMapping.create!(user: u2, entity: @line_item1, twilio_number: TwilioNumber.first)
    m = PhoneMapping.create!(user: @user, entity: @line_item1, twilio_number: TwilioNumber.first)
    assert_equal m, PhoneMapping.mapping_for(@user, @line_item1)
  end
end
