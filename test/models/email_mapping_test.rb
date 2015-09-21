require 'test_helper'

class EmailMappingTest < ActiveSupport::TestCase
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

  test 'it should save an email mapping' do
    mapping = @user.email_mappings.new(entity: @line_item1)

    assert_difference 'EmailMapping.count' do
      mapping.save
    end
  end

  test 'it should not generate a new mapping if there is already one' do
    EmailMapping.any_instance.unstub(:generate_code)
    EmailMapping.create_for(@user, @line_item1)

    assert_no_difference "EmailMapping.count" do
      EmailMapping.create_for(@user, @line_item1)
    end
  end

  test 'code must be unique' do
    EmailMapping.any_instance.unstub(:generate_code)
    mapping2 = EmailMapping.create_for(@user, @line_item2)
    mapping3 = EmailMapping.create_for(@user, @line_item3)

    assert_not_equal mapping2.code, mapping3.code
  end

  test 'code should be downcase' do
    EmailMapping.any_instance.unstub(:generate_code)
    SecureRandom.stubs(:urlsafe_base64).returns('UPCASE123456')
    m = EmailMapping.create_for(@user, @line_item2)
    assert_equal 'upcase123456', m.code
  end

  test "it should respond to create_for" do
    assert_respond_to EmailMapping, :create_for
  end

  test "create_for should create a mapping for a given user and line item" do
    EmailMapping.any_instance.unstub(:generate_code)
    assert_difference "EmailMapping.count" do
      mapping = EmailMapping.create_for(@user, @line_item1)

      assert_equal  @user, mapping.user
      assert_equal  @line_item1, mapping.line_item
    end
  end

  test 'email_address should return an email address built with its code and the domain given' do
    mapping = EmailMapping.create_for(@user, @line_item1)
    mapping.stubs(:code).returns('123456789abc')
    mapping.entity.expects(:mail_prefix).with(@user).returns('a_prefix')
    assert_equal "a_prefix+123456789abc@domain.com", mapping.email_address('domain.com')
  end
end