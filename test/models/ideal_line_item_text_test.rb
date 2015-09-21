require 'test_helper'

class IdealLineItemTextTest < ActiveSupport::TestCase
  test "to_sentence should return a string composed by ideal_start" do
    li = LineItem.new(earliest_start: Time.zone.parse('10 Jan 2014 04:00:00 PM UTC'),
                      ideal_start: Time.zone.parse('10 Jan 2014 05:00:00 PM UTC'),
                      finish_by: Time.zone.parse('11 Jan 2014 01:00:00 AM UTC'))
    li.stubs(:time_zone).returns('UTC')

    assert_equal "(ideally 5pm)", IdealLineItemText.new(li).to_sentence
  end

  test "to_sentence should add date for ideal start if finish_by >=24 hours after start_by" do
    li = LineItem.new(earliest_start: Time.zone.parse('10 Jan 2014 04:00:00 PM UTC'),
                      ideal_start: Time.zone.parse('10 Jan 2014 05:00:00 PM UTC'),
                      finish_by: Time.zone.parse('11 Jan 2014 06:00:00 PM UTC'))
    li.stubs(:time_zone).returns('UTC')

    assert_equal "(ideally 1/10 5pm)", IdealLineItemText.new(li).to_sentence
  end

  test "to_sentence should add date for ideal start if finish_by >=24 hours after start_by and use today/tomorrow" do
    ideal = Time.zone.now
    li = LineItem.new(earliest_start: ideal,
                      ideal_start: ideal,
                      finish_by: Time.zone.now.tomorrow)
    li.stubs(:time_zone).returns('UTC')

    assert_equal "(ideally today #{ TimeHelper.format(ideal, 'UTC') })", IdealLineItemText.new(li).to_sentence
  end

  test "to_sentence should use today/tomorrow" do
    ideal = Time.zone.now
    li = LineItem.new(earliest_start: ideal,
                      ideal_start: ideal,
                      finish_by: ideal)
    li.stubs(:time_zone).returns('UTC')

    assert_equal "(ideally #{ TimeHelper.format(ideal, 'UTC') })", IdealLineItemText.new(li).to_sentence
  end

  test 'with_no_start should return ideal date and time if finish date is not today' do
    ideal = Time.new(2020, 2, 3, 10, 20, 5, '+00:00')
    li = LineItem.new(ideal_start: ideal,
                      finish_by: ideal)
    li.stubs(:time_zone).returns('UTC')
    assert_equal( { ideal_date: '2/3', ideal_time: '10:20am' }, IdealLineItemText.new(li).send(:with_no_start))
  end

  test 'with_no_start should return ideal time if finish date is today' do
    ideal = Time.new(2020, 2, 3, 10, 20, 5, '+00:00')
    li = LineItem.new(ideal_start: ideal,
                      finish_by: ideal)
    li.stubs(:time_zone).returns('UTC')
    DateHelper.expects(:today?).returns(true)
    assert_equal( { ideal_time: '10:20am' }, IdealLineItemText.new(li).send(:with_no_start))
  end

  test 'with_no_start_and_no_finish should return ideal date and time' do
    ideal = Time.new(2020, 2, 3, 10, 20, 5, '+00:00')
    li = LineItem.new(ideal_start: ideal)
    li.stubs(:time_zone).returns('UTC')
    assert_equal( { ideal_date: '2/3', ideal_time: '10:20am' }, IdealLineItemText.new(li).send(:with_no_start_and_no_finish))
  end

  test 'complete should call with_no_start_and_no_finish if the time frame is greater than 24 hours' do
    ideal = Time.new(2020, 2, 3, 10, 20, 5, '+00:00')
    li = LineItem.new(ideal_start: ideal, earliest_start: ideal - 1.day, finish_by: ideal + 1.day)
    li.stubs(:time_zone).returns('UTC')
    helper = IdealLineItemText.new(li)
    helper.expects(:with_no_start_and_no_finish)
    helper.send(:complete)
  end

  test 'complete should call ideal_time if the time frame is shorter than 24 hours' do
    ideal = Time.new(2020, 2, 3, 10, 20, 5, '+00:00')
    li = LineItem.new(ideal_start: ideal, earliest_start: ideal - 1.hour, finish_by: ideal + 1.hour)
    li.stubs(:time_zone).returns('UTC')
    helper = IdealLineItemText.new(li)
    helper.expects(:ideal_time)
    helper.send(:complete)
  end

  test 'ideal_date should return the human readable ideal date' do
    ideal = Time.new(2020, 2, 3, 10, 20, 5, '+00:00')
    li = LineItem.new(ideal_start: ideal)
    li.stubs(:time_zone).returns('UTC')
    assert_equal '2/3', IdealLineItemText.new(li).send(:ideal_date)
  end

  test 'ideal_time should return the human readable ideal date' do
    ideal = Time.new(2020, 2, 3, 10, 20, 5, '+00:00')
    li = LineItem.new(ideal_start: ideal)
    li.stubs(:time_zone).returns('UTC')
    assert_equal '10:20am', IdealLineItemText.new(li).send(:ideal_time)
  end

  test 'wrap_with_agreement should wrap the date with (ideally) if the line item is not accepted' do
    li = LineItem.new
    assert_equal( { ideal_date: '(ideally some date', ideal_time: 'some time)' }, IdealLineItemText.new(li).send(:wrap_with_agreement, ideal_date: 'some date', ideal_time: 'some time'))
  end

  test 'wrap_with_agreement should prepend agreed to the date if the line item is accepted' do
    li = LineItem.new(status: LineItemState::ACCEPTED)
    assert_equal( { ideal_date: 'agreed some date', ideal_time: 'some time' }, IdealLineItemText.new(li).send(:wrap_with_agreement, ideal_date: 'some date', ideal_time: 'some time'))
  end
end