require 'test_helper'

class UrlMappingTest < ActiveSupport::TestCase
  def setup
    super
    request = Request.new
    request.save(validate: false)
    @line_item1 = LineItem.new(request: request)
    @line_item2 = LineItem.new(request: request)

    @line_item1.stubs(:populate_from_parent).returns(true)
    @line_item2.stubs(:populate_from_parent).returns(true)

    @line_item1.save(validate: false)
    @line_item2.save(validate: false)

    @contact_point1 = ContactPoint::Sms.create!(description: '14157637901', user: User.new)

    @previous_max_length = SmsMessage::MAX_LENGTH
  end

  def teardown
    super
    SmsMessage.send(:remove_const, :MAX_LENGTH)
    SmsMessage.const_set(:MAX_LENGTH, @previous_max_length)
  end

  should belong_to :contact_point
  should have_one(:user).through(:contact_point)

  should validate_uniqueness_of(:path).scoped_to(:contact_point_id)

  test 'it should save an url mapping' do
    mapping = UrlMapping.new(contact_point: @contact_point1, path: '/a_path')

    assert_difference 'UrlMapping.count' do
      mapping.save
    end
  end

  test 'it should not generate a new mapping if there is already one' do
    UrlMapping.create_for(@contact_point1)

    assert_no_difference 'UrlMapping.count' do
      UrlMapping.create_for(@contact_point1)
    end
  end

  test 'code must be unique' do
    mapping = UrlMapping.create_for(@contact_point1, @line_item1)
    mapping2 = UrlMapping.create_for(@contact_point1, @line_item2)
    assert_not_equal mapping.code, mapping2.code
  end

  test 'closed codes should be ignored' do
    mapping = UrlMapping.create_for(@contact_point1, @line_item1)
    mapping.update_attributes(status: MappingState::CLOSED)
    assert_raises(NoRouteFoundException) { UrlMapping.fetch_mapping!(mapping.code) }
  end

  test 'it should respond to create_for' do
    assert_respond_to UrlMapping, :create_for
  end

  test 'create_for should use the mappeable mapping_path as path' do
    @line_item1.expects(:mapping_path).returns('/some/path')
    assert_difference 'UrlMapping.count' do
      mapping = UrlMapping.create_for(@contact_point1, @line_item1)
      assert_equal @contact_point1, mapping.contact_point
      assert_equal '/some/path', mapping.path
    end
  end

  test 'create_for should use the contact_points_path if no mappeable is given' do
    UrlMapping.destroy_all
    assert_difference 'UrlMapping.count' do
      mapping = UrlMapping.create_for(@contact_point1)
      assert_equal @contact_point1, mapping.contact_point
      assert_equal '/contact_points', mapping.path
    end
  end

  test "it should respond to fetch_mapping!" do
    assert_respond_to UrlMapping, :fetch_mapping!
  end

  test "fetch_mapping! should get a url_mapping for a given code" do
    mapping = UrlMapping.create_for(@contact_point1, @line_item1)
    code = mapping.code
    fetched_mapping = UrlMapping.fetch_mapping!(code)

    assert_equal mapping, fetched_mapping
  end

  test "fetch_mapping! should raise a InvalidCodeException if there is no mapping with the given code" do
    mapping = UrlMapping.create_for(@contact_point1, @line_item1)
    impossible_code = mapping.code.next
    assert_raises(NoRouteFoundException) { UrlMapping.fetch_mapping!(impossible_code) }
  end

  test 'attach_to should append a url to the text' do
    mapping = UrlMapping.new
    mapping.stubs(:to_short_url).returns('my.url.com/12345678')
    assert_equal 'text my.url.com/12345678', mapping.attach_to('text')
  end

  test 'attach_to should join the text and the url with the separator given' do
    mapping = UrlMapping.new
    mapping.stubs(:to_short_url).returns('my.url.com/12345678')
    assert_equal 'textSEPARATORmy.url.com/12345678', mapping.attach_to('text', separator: 'SEPARATOR')
  end

  test 'attach_to should join the text and the url with a space if it is called without separator' do
    mapping = UrlMapping.new
    mapping.stubs(:to_short_url).returns('my.url.com/12345678')
    assert_equal 'text my.url.com/12345678', mapping.attach_to('text')
  end

  test 'attach_to should leave the body unchanged if attaching the url would trigger the creation of another sms message' do
    SmsMessage.send(:remove_const, :MAX_LENGTH)
    SmsMessage.const_set(:MAX_LENGTH, 40)
    body_for_1_sms_but_without_space_for_url = token_of_length(30)
    body_for_2_sms_but_without_space_for_url = token_of_length(61)
    body_for_2_sms_with_space_for_url = token_of_length(60)
    body_for_1_sms_with_max_size = token_of_length(40)
    mapping = UrlMapping.new
    mapping.stubs(:to_short_url).returns('my.url.com/12345678')
    assert_equal body_for_1_sms_but_without_space_for_url, mapping.attach_to(body_for_1_sms_but_without_space_for_url)
    assert_equal body_for_2_sms_but_without_space_for_url, mapping.attach_to(body_for_2_sms_but_without_space_for_url)
    assert_equal body_for_1_sms_with_max_size, mapping.attach_to(body_for_1_sms_with_max_size)
    assert_equal "#{ body_for_2_sms_with_space_for_url } my.url.com/12345678", mapping.attach_to(body_for_2_sms_with_space_for_url)
  end

  test 'static_mapping should create a mapping unrelated to any contact point' do
    UrlMapping.expects(:some_named_route_path).with(some: :params).returns('/')
    assert_difference 'UrlMapping.count' do
      created = UrlMapping.static_mapping(:some_named_route, some: :params)
      assert_equal '/', created.path
      assert_nil created.contact_point
    end
  end

  test 'static_mapping should avoid recreating a mapping for the same path' do
    UrlMapping.stubs(:some_named_route_path).returns('some_path')
    existing_mapping = UrlMapping.create!(path: 'some_path')
    assert_no_difference 'UrlMapping.count' do
      created = UrlMapping.static_mapping(:some_named_route)
      assert_equal existing_mapping.id, created.id
    end
  end

  test 'to_short_url should return a url with the code and host set to the env var URL_MAPPING_HOST' do
    ENV.stubs(:[]).with('URL_MAPPING_HOST').returns('some.host.com')
    mapping = UrlMapping.new(code: 'somecode')
    assert_equal 'some.host.com/somecode', mapping.to_short_url
  end

  test 'to_url without parameters should return a url with the code and host set to the env var HOST_URL' do
    ENV.stubs(:[]).with('HOST_URL').returns('another.host.com')
    mapping = UrlMapping.new(code: 'somecode')
    assert_equal 'another.host.com/somecode', mapping.to_url
  end

  test 'to_url should return a url with the code and host set to the host given' do
    mapping = UrlMapping.new(code: 'somecode')
    assert_equal 'yet.another.host.com/somecode', mapping.to_url('yet.another.host.com')
  end
end