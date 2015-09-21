require 'test_helper'

class ScheduleLineItemTextTest < ActiveSupport::TestCase
  test "to_sentence should return a string composed by earliest_start, finish_by and ideal_start" do
    start = Time.zone.parse('10 Jan 2014 04:00:00 PM UTC')
    finish = Time.zone.parse('11 Jan 2014 01:00:00 AM UTC')

    assert_equal "on 1/10 between 4pm-1am", ScheduleLineItemText.to_sentence(start,finish, "UTC")
  end
  
  test "to_sentence should add date for start and finish by if finish_by >=24 hours after start_by" do
    start =  Time.zone.parse('10 Jan 2014 04:00:00 PM UTC')
    finish = Time.zone.parse('11 Jan 2014 06:00:00 PM UTC')

    assert_equal "between 1/10 4pm-1/11 6pm", ScheduleLineItemText.to_sentence(start,finish, "UTC")
  end

  test "to_sentence should add date forstart and finish by if finish_by >=24 hours after start_by and use today/tomorrow" do
    start = Time.zone.now
    finish = Time.zone.now.tomorrow
    tmz = "UTC"

    assert_equal "between today #{TimeHelper.format(start,tmz)}-tomorrow #{TimeHelper.format(finish,tmz)}", ScheduleLineItemText.to_sentence(start,finish,tmz)
  end

  test "to_sentence should use today/tomorrow" do
    start = Time.zone.now
    finish = Time.zone.now
    tmz = "UTC"

    assert_equal "today between #{TimeHelper.format(start,tmz)[0..-3]}-#{TimeHelper.format(finish,tmz)}", ScheduleLineItemText.to_sentence(start,finish, tmz)
  end

  test "to_sentence should ignore earliest_start if not present and use today" do
    start = nil
    finish = Time.zone.now
    tmz = "UTC"

    assert_equal "finishing by today #{TimeHelper.format(finish,tmz)}",
                   ScheduleLineItemText.to_sentence(start,finish, tmz)
  end

  test "to_sentence should ignore earliest_start if not present" do
    start = nil
    finish = Time.zone.parse('11 Jan 2014 01:00:00 AM UTC')

    assert_equal "finishing by 1/11 1am", ScheduleLineItemText.to_sentence(start,finish, "UTC")
  end

  test "to_sentence should ignore finish_by if not present" do
    start = Time.zone.parse('10 Jan 2014 01:00:00 PM UTC')
    finish = nil
    tmz = "UTC"

    assert_equal "at or after 1/10 1pm", ScheduleLineItemText.to_sentence(start,finish, tmz)
  end

  test "to_sentence should ignore finish_by if not present and use today/tomorrow" do
    start =  Time.zone.now
    finish = nil
    tmz = "UTC"

    assert_equal "at or after today #{TimeHelper.format(start,tmz)}", 
                    ScheduleLineItemText.to_sentence(start,finish, tmz)
  end

  test "to_sentence should ignore finish_by and start_by if are not present" do
    start =  nil
    finish = nil
    tmz = "UTC"

    assert_nil ScheduleLineItemText.to_sentence(start,finish, tmz)
  end
end