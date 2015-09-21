require 'test_helper'

class TwilioNumberTest < ActiveSupport::TestCase
  should have_one :request

  should validate_presence_of :number
  should validate_uniqueness_of :number

  def setup
    super
    @user = create_user
  end

  test 'default_number should return the first non reserved number in the db' do
    TwilioNumber.find_each(&:destroy)

    t1 = TwilioNumber.create(number: '11111')
    t2 = TwilioNumber.create(number: '22222')
    Request.new(reserved_number: t1).save!(validate: false)

    assert_equal t1, TwilioNumber.first
    assert_equal t2, TwilioNumber.default_number
  end

  test 'default_number should buy a number if all the numbers are reserved' do
    TwilioNumber.find_each(&:destroy)

    t1 = TwilioNumber.create(number: '11111')
    Request.new(reserved_number: t1).save!(validate: false)

    TwilioNumber.expects(:buy_and_store_number).with
    TwilioNumber.default_number
  end

  test 'load_twilio_numbers should fetch the numbers via the twilio api' do
    TwilioApi.expects(:incoming_numbers).returns([])
    TwilioNumber.load_twilio_numbers
  end

  test 'load_twilio_numbers should create a twilio number for each number fetched' do
    TwilioNumber.delete_all
    TwilioApi.stubs(:incoming_numbers).returns(['1111', '2222'])
    TwilioNumber.load_twilio_numbers
    numbers = TwilioNumber.order('number').to_a
    assert_equal 2, TwilioNumber.count
    assert_equal '1111', numbers[0].number
    assert_equal '2222', numbers[1].number
  end

  test 'load_twilio_numbers should destroy the numbers no longer available' do
    TwilioNumber.delete_all
    old_number = TwilioNumber.create!(number: '1111')
    TwilioApi.stubs(:incoming_numbers).returns(['2222'])
    TwilioNumber.load_twilio_numbers
    assert !TwilioNumber.where(number: '1111').exists?
  end

  test 'number_for_user should keep using the previously chosen number for an old line_item' do
    @line_item1 = stubbed_line_item
    mapping = @user.phone_mappings.create!(twilio_number: TwilioNumber.first, entity: @line_item1)
    TwilioNumber.create(number: 'another number')

    assert_equal mapping.twilio_number, TwilioNumber.number_for_user(@user, @line_item1)
  end

  test 'number_for_user should not choose a number for an old user and line item that already have a mapping' do
    @line_item1 = stubbed_line_item
    @user.phone_mappings.create!(twilio_number: TwilioNumber.first, entity: @line_item1)

    TwilioNumber.expects(:less_used_number).never
    TwilioNumber.number_for_user(@user, @line_item1)
  end

  test 'number_for_user should choose the less used number for the given user and line item' do
    @line_item1 = stubbed_line_item

    TwilioNumber.expects(:less_used_number).returns(TwilioNumber.new(number: '13451111111'))
    TwilioNumber.number_for_user(@user, @line_item1)
  end

  test 'number_for_user should buy a new number with the users preferred area code if there is no available number' do
    TwilioNumber.find_each(&:destroy)
    @line_item1 = stubbed_line_item

    @user.expects(:preferred_area_code).returns('123')
    TwilioNumber.expects(:buy_and_store_number).with('123').returns(TwilioNumber.new(number: '11239999999'))
    assert_equal '11239999999', TwilioNumber.number_for_user(@user, @line_item1).number
  end

  test 'less_used_number should return the twilio number with less mappings for a given user' do
    @line_item1 = stubbed_line_item
    @line_item2 = stubbed_line_item
    @line_item3 = stubbed_line_item
    n1 = TwilioNumber.first
    n2 = TwilioNumber.create(number: '1234')
    @user.phone_mappings.create!(twilio_number: n1, entity: @line_item1)
    @user.phone_mappings.create!(twilio_number: n1, entity: @line_item2)
    @user.phone_mappings.create!(twilio_number: n2, entity: @line_item3)

    assert_equal n2, TwilioNumber.less_used_number(@user)
  end

  test 'less_used_number should ignore closed mappings' do
    li1 = stubbed_line_item
    li2 = stubbed_line_item
    li3 = stubbed_line_item
    li4 = stubbed_line_item
    li5 = stubbed_line_item
    n1 = TwilioNumber.first
    n2 = TwilioNumber.create(number: '1234')
    #2 active
    @user.phone_mappings.create!(twilio_number: n1, entity: li1)
    @user.phone_mappings.create!(twilio_number: n1, entity: li2)
    #1 active 2 closed
    @user.phone_mappings.create!(twilio_number: n2, entity: li3)
    @user.phone_mappings.create!(twilio_number: n2, entity: li4, status: MappingState::CLOSED)
    @user.phone_mappings.create!(twilio_number: n2, entity: li5, status: MappingState::CLOSED)

    assert_equal n2, TwilioNumber.less_used_number(@user)
  end

  test 'less_used_number should ignore numbers reserved for requests' do
    n1 = TwilioNumber.first
    assert_equal n1, TwilioNumber.less_used_number(@user)
    r = Request.new(reserved_number: n1)
    r.save!(validate: false)
    assert_nil TwilioNumber.less_used_number(@user)
  end

  test 'buy_and_store_number should call buy_number on TwilioApi' do
    TwilioApi.expects(:buy_number).with('100').returns('+15005550010')
    TwilioNumber.buy_and_store_number('100')
  end

  test 'buy_and_store_number should store the number buyed' do
    TwilioApi.stubs(:buy_number).returns('+15005550010')

    assert_difference('TwilioNumber.count') do
      TwilioNumber.buy_and_store_number('100')
    end
    assert_equal '15005550010', TwilioNumber.last.number
  end

  test 'available should merge not_reserved with not_mapped' do
    TwilioNumber.expects(:not_reserved).returns(TwilioNumber.all)
    TwilioNumber.expects(:not_mapped)
    TwilioNumber.available.to_a
  end

  test 'reserved_ids should fetch the ids of the numbers associated with an open request' do
    TwilioNumber.find_each(&:destroy)
    #with open request
    t1 = TwilioNumber.create!(number: '13451111111')
    #with closed request
    t2 = TwilioNumber.create!(number: '13451111112')
    #without request
    TwilioNumber.create!(number: '13451111113')

    r1 = Request.new(reserved_number: t1)
    r1.save(validate: false)
    r2 = Request.new(reserved_number: t2, status: RequestState::CLOSED)
    r2.save(validate: false)
    assert_equal [t1.id], TwilioNumber.send(:reserved_ids)
  end

  test 'mapped_ids should fetch the ids of the numbers associated with at least one active phone mapping' do
    TwilioNumber.find_each(&:destroy)
    PhoneMapping.any_instance.stubs(:generate_code)
    #with active mapping
    t1 = TwilioNumber.create!(number: '13451111111')
    #with closed mapping
    t2 = TwilioNumber.create!(number: '13451111112')
    #without mapping
    TwilioNumber.create!(number: '13451111113')

    m1 = PhoneMapping.new(twilio_number: t1)
    m1.save(validate: false)
    m2 = PhoneMapping.new(twilio_number: t2, status: MappingState::CLOSED)
    m2.save(validate: false)
    assert_equal [t1.id], TwilioNumber.send(:mapped_ids)
  end

  test 'not_reserved should include the records whose id is not in reserved_ids' do
    TwilioNumber.find_each(&:destroy)
    t1 = TwilioNumber.create!(number: '13451111111')
    t2 = TwilioNumber.create!(number: '13451111112')
    t3 = TwilioNumber.create!(number: '13451111113')
    t4 = TwilioNumber.create!(number: '13451111114')
    TwilioNumber.expects(:reserved_ids).returns([t1.id, t2.id])
    assert_equal [t3, t4], TwilioNumber.not_reserved.to_a
  end

  test 'not_mapped should include the records whose id is not in mapped_ids' do
    TwilioNumber.find_each(&:destroy)
    t1 = TwilioNumber.create!(number: '13451111111')
    t2 = TwilioNumber.create!(number: '13451111112')
    t3 = TwilioNumber.create!(number: '13451111113')
    t4 = TwilioNumber.create!(number: '13451111114')
    TwilioNumber.expects(:mapped_ids).returns([t1.id, t2.id])
    assert_equal [t3, t4], TwilioNumber.not_mapped.to_a
  end

  test 'area_code should return its area code' do
    t = TwilioNumber.create!(number: '16501111111')
    assert_equal '650', t.area_code
  end

  test 'available_number should return the first number matching the area code given' do
    TwilioNumber.find_each(&:destroy)

    TwilioNumber.create!(number: '13451111111')
    TwilioNumber.create!(number: '13461111111')
    matching = TwilioNumber.create!(number: '13471111111')
    assert_equal matching, TwilioNumber.available_number('347')
  end

  test 'available_number should return the first number if there is no number matching the area code given' do
    TwilioNumber.find_each(&:destroy)

    first = TwilioNumber.create!(number: '13451111111')
    TwilioNumber.create!(number: '13461111111')
    TwilioNumber.create!(number: '13471111111')
    assert_equal first, TwilioNumber.available_number('348')
  end

  test 'available_number should buy a new number with the area code given if there is no available number' do
    TwilioNumber.find_each(&:destroy)

    reserved = TwilioNumber.create!(number: '13451111111')
    Request.new(reserved_number: reserved).save!(validate: false)

    TwilioNumber.expects(:buy_and_store_number).with('345').returns(TwilioNumber.new(number: '13451111112'))
    assert_equal '13451111112', TwilioNumber.available_number('345').number
  end

  test 'to_s should return the denormalized number' do
    t = TwilioNumber.new(number: '13451234567')
    assert_equal '(345) 123-4567', t.to_s
  end

  test 'request should return the first open request' do
    tn = TwilioNumber.first
    r = Request.new(reserved_number: tn)
    r.save!(validate: false)
    assert_equal r, tn.request
    r.close(User.first)
    assert_nil tn.reload.request
    r2 = Request.new(reserved_number: tn)
    r2.save!(validate: false)
    assert_equal r2, tn.reload.request
  end

  test 'reserved? should return true if there is a request associated with the number' do
    tn = TwilioNumber.first
    assert !tn.reserved?
    Request.new(reserved_number: tn).save!(validate: false)
    assert tn.reload.reserved?
  end

  test 'caller_id_for_number should fetch the contact point whose number is the number given' do
    request = Request.new
    request.stubs(receiver_for_reserved_message: stub(author_mapping: stub(twilio_number: TwilioNumber.new(number: '13456666666'))))
    tn = TwilioNumber.default_number
    tn.stubs(:request).returns(request)
    VoiceSender.expects(:number_to_contact).with('a number').returns(nil)
    tn.caller_id_for_number('a number')
  end

  test 'caller_id_for_number should return the number of the twilio number of the author mapping of the receiver of the call based on the number given' do
    request = Request.new
    request.stubs(receiver_for_reserved_message: stub(author_mapping: stub(twilio_number: TwilioNumber.new(number: '13456666666'))))
    tn = TwilioNumber.default_number
    tn.stubs(:request).returns(request)

    assert_equal '13456666666', tn.caller_id_for_number('13459999999')
  end

  test 'caller_id_for_number should return the number of the twilio number of the author mapping of the first line item of the request if the number given is anonymous' do
    request = Request.new
    request.stubs(first_line_item: stub(author_mapping: stub(twilio_number: TwilioNumber.new(number: '13456666666'))))
    tn = TwilioNumber.default_number
    tn.stubs(:request).returns(request)

    assert_equal '13456666666', tn.caller_id_for_number('266696687')
  end

  test 'close request should close its request' do
    request = Request.new
    tn = TwilioNumber.default_number
    tn.stubs(:request).returns(request)
    request.expects(:close_dependencies)
    tn.send(:close_request)
  end

  test 'close request should be called before destroy' do
    tn = TwilioNumber.default_number
    tn.expects(:close_request)
    tn.destroy
  end

  def stubbed_line_item(request = nil)
    request ||= Request.new time_zone: "Buenos Aires", earliest_start: Time.now, finish_by: Time.now
    request.save(validate: false)
    LineItem.new(request: request).tap do |li|
      li.stubs(:populate_from_parent).returns(true)
      li.save(validate: false)
    end
  end
end