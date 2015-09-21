require 'test_helper'

class PhoneMappingTest < ActiveSupport::TestCase
  def setup
    super
    request = Request.new time_zone: "Buenos Aires", earliest_start: Time.now, finish_by: Time.now
    request.save(validate: false)

    @line_item1 = LineItem.new request: request
    @line_item2 = LineItem.new request: request
    @line_item3 = LineItem.new request: request

    @line_item1.stubs(:populate_from_parent).returns(true)
    @line_item2.stubs(:populate_from_parent).returns(true)
    @line_item3.stubs(:populate_from_parent).returns(true)

    @line_item1.save(validate: false)
    @line_item2.save(validate: false)
    @line_item3.save(validate: false)

    @user = create_user
    @user2 = create_user(name: 'u2', uniqueid: 'u2')

    @number = TwilioNumber.default_number
    PhoneMapping.any_instance.stubs(:generate_code)
  end

  should validate_presence_of :twilio_number
  should validate_uniqueness_of :endpoint_id

  should belong_to :twilio_number

  test 'it should save a phone mapping' do
    mapping = @user.phone_mappings.new(entity: @line_item1, twilio_number: @number)

    assert_difference "PhoneMapping.count" do
      mapping.save
    end
  end

  test 'it should not generate a new mapping if there is already one' do
    PhoneMapping.any_instance.unstub(:generate_code)
    PhoneMapping.create_for(@user, @line_item1, @number)

    assert_no_difference "PhoneMapping.count" do
      PhoneMapping.create_for(@user, @line_item1, @number)
    end
  end

  test 'it should not generate a code for the first mapping of a phone number' do
    PhoneMapping.any_instance.unstub(:generate_code)
    mapping = PhoneMapping.create_for(@user, @line_item1, @number)
    assert_equal '1',mapping.code
  end

  test 'it should generate a code during for the second outstanding message' do
    PhoneMapping.any_instance.unstub(:generate_code)
    mapping1 = PhoneMapping.create_for(@user, @line_item1, @number)
    mapping2 = PhoneMapping.create_for(@user, @line_item2, @number)

    assert_equal '1', mapping1.code
    assert_equal '2', mapping2.code
  end

  test 'code must be unique' do
    PhoneMapping.any_instance.unstub(:generate_code)
    PhoneMapping.create_for(@user, @line_item1, @number)
    mapping2 = PhoneMapping.create_for(@user, @line_item2, @number)
    mapping3 = PhoneMapping.create_for(@user, @line_item3, @number)

    assert_not_equal mapping2.code, mapping3.code
  end

  test 'code must be unique within user' do
    PhoneMapping.any_instance.unstub(:generate_code)
    PhoneMapping.create_for(@user, @line_item1, @number)
    PhoneMapping.create_for(@user2, @line_item1, @number)

    mapping3 = PhoneMapping.create_for(@user, @line_item2, @number)
    mapping4 = PhoneMapping.create_for(@user2, @line_item2, @number)

    assert_equal mapping3.code, mapping4.code
  end

  test 'code must be shared for the same line_item' do
    PhoneMapping.any_instance.unstub(:generate_code)
    PhoneMapping.create_for(@user, @line_item1, @number)
    PhoneMapping.create_for(@user, @line_item2, @number)
    mapping3 = PhoneMapping.create_for(@user, @line_item3, @number)
    mapping4 = PhoneMapping.create_for(@user, @line_item3, @number)

    assert_equal mapping3.code, mapping4.code
  end

  test 'closed codes should be ignored' do
    PhoneMapping.any_instance.unstub(:generate_code)
    mapping1 = PhoneMapping.create_for(@user, @line_item1, @number)
    mapping1.status = MappingState::CLOSED
    mapping1.save

    mapping2 = PhoneMapping.create_for(@user, @line_item2, @number)

    assert_equal mapping1.code, mapping2.code
  end

  test "it should respond to create_for" do
    assert_respond_to PhoneMapping, :create_for
  end

  test "create_for should create a mapping for a given user and line item" do
    PhoneMapping.any_instance.unstub(:generate_code)
    assert_difference "PhoneMapping.count" do
      mapping = PhoneMapping.create_for(@user, @line_item1, @number)

      assert_equal  @user, mapping.user
      assert_equal  @line_item1, mapping.line_item
    end
  end

  test "it should respond to parse_code" do
    assert_respond_to PhoneMapping, :parse_code
  end

  test "parse_code should strip the code from the beg of the message" do
    assert_equal "123456", PhoneMapping.parse_code("123456 Hey There")
  end

  test "parse_code should return nil if it cant find a code" do
    assert_nil PhoneMapping.parse_code("Hey There I wanna a lesson for $10")
  end

  test "it should respond to strip_code" do
    assert_respond_to PhoneMapping, :parse_code
  end

  test 'strip_code should return the message without the code at the beginning' do
    assert_equal 'Hey There', PhoneMapping.strip_code('123456 Hey There')
  end

  test 'strip_code should return the original message if it cant find a code' do
    body = 'Hey There I wanna a lesson for $10'
    assert_equal body, PhoneMapping.strip_code(body)
  end

  test 'attach_to should prepend the text with a code if it needs a code' do
    mapping = PhoneMapping.new
    mapping.stubs(:needs_code?).returns(true)
    mapping.stubs(:code).returns(1)
    assert_equal '1: text', mapping.attach_to('text')
  end

  test 'attach_to should keep the text unchanged if it doesnt need a code' do
    mapping = PhoneMapping.new
    mapping.stubs(:needs_code?).returns(false)
    assert_equal 'text', mapping.attach_to('text')
  end

  test 'needs_code? should return true if there are more active mappings for its user and its number' do
    mapping = @user.phone_mappings.build(twilio_number: @number)
    mapping.save(validate: false)
    other_mapping = @user.phone_mappings.build(twilio_number: @number)
    other_mapping.save(validate: false)

    assert mapping.needs_code?
  end

  test 'needs_code? should return false if it is the only active mapping for its user and its number' do
    mapping = @user.phone_mappings.build(twilio_number: @number)
    mapping.save(validate: false)

    assert !mapping.needs_code?
  end

  test 'for_twilio scope should include mappings whose twilio_number number is the number given' do
    m = PhoneMapping.new(twilio_number: @number)
    m.save(validate: false)
    assert_equal [m], PhoneMapping.for_twilio(@number.number)
  end

  test 'for_twilio scope should exclude mappings whose twilio_number number is not the number given' do
    m = PhoneMapping.new(twilio_number: @number)
    m.save(validate: false)
    assert_equal [], PhoneMapping.for_twilio(@number.number.succ)
  end

  test 'for_twilio scope should include mappings whose twilio_number instance is the number given' do
    m = PhoneMapping.new(twilio_number: @number)
    m.save(validate: false)
    PhoneMapping.new(twilio_number: TwilioNumber.create(number: '13459595959')).save(validate: false)
    assert_equal [m], PhoneMapping.for_twilio(@number)
  end

  test 'voice_number should delegate to entity' do
    m = PhoneMapping.new(entity: @line_item1, user: @user)
    @line_item1.expects(:voice_number).with(@user)
    m.voice_number
  end

  test 'resource_full_name should delegate to entity' do
    m = PhoneMapping.new(entity: @line_item1, user: @user)
    @line_item1.expects(:resource_full_name).with(@user)
    m.resource_full_name
  end

  test 'caller_info should return the caller_info of the entity' do
    m = PhoneMapping.new(entity: @line_item1, user: @user)
    @line_item1.expects(:caller_info).with(@user).returns('something')
    assert_equal 'something', m.caller_info
  end

  test 'generate_code should choose the succ of the max code with numeric order' do
    PhoneMapping.create!(user: @user, twilio_number: TwilioNumber.default_number, entity: @line_item1, code: '9')
    PhoneMapping.create!(user: @user, twilio_number: TwilioNumber.default_number, entity: @line_item2, code: '10')
    PhoneMapping.any_instance.unstub(:generate_code)
    last = PhoneMapping.create!(user: @user, twilio_number: TwilioNumber.default_number, entity: @line_item3)
    #alphabetic order would give '10' again
    assert_equal '11', last.code
  end
end
