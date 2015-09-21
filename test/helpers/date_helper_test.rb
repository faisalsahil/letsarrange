require 'test_helper'

class DateHelperTest < ActiveSupport::TestCase

  def setup
    super
    @pst = "Pacific Time (US & Canada)" #PST is -7
  end

  test "today? should be true if the date has the same day as Time.now in the given tmz" do 
    Timecop.freeze(Time.parse("10 Jan 2014 10:00:00 AM UTC")) do
      assert DateHelper.today?(Time.parse('11 Jan 2014 02:00:00 AM UTC'), @pst)
    end
  end

  test "today? should be DTS aware" do 
    Timecop.freeze(Time.parse("10 Jan 2014 10:00:00 AM UTC")) do
      assert DateHelper.today?(Time.parse('11 Jan 2014 07:00:00 AM UTC'), @pst)              
    end

    Timecop.freeze(Time.parse("10 Mar 2014 10:00:00 AM UTC")) do
      assert !DateHelper.today?(Time.parse('11 Mar 2014 07:00:00 AM UTC'), @pst)              
    end
  end

  test "tomorrow? should be true if the date has the same day as Time.now.tomorrow in the given tmz" do 
    Timecop.freeze(Time.parse("10 Jan 2014 10:00:00 AM UTC")) do
      assert DateHelper.tomorrow?(Time.parse('11 Jan 2014 02:00:00 PM UTC'), @pst)
    end
  end

  test "tomorrow? should be DTS aware" do 
    Timecop.freeze(Time.parse("10 Jan 2014 10:00:00 AM UTC")) do
      assert !DateHelper.tomorrow?(Time.parse('11 Jan 2014 07:00:00 AM UTC'), @pst)              
    end

    Timecop.freeze(Time.parse("10 Mar 2014 10:00:00 AM UTC")) do
      assert DateHelper.tomorrow?(Time.parse('11 Mar 2014 07:00:00 AM UTC'), @pst)              
    end
  end

  test "format should return a string container month/day without leadding zeros" do 
    Timecop.freeze(Time.parse("10 Jan 2014 10:00:00 AM UTC")) do
      assert_equal "1/13", DateHelper.format(Time.parse('13 Jan 2014 02:00:00 PM UTC'), @pst)          
    end
  end

  test "format should return the string 'today' if the date is equal to current date" do 
    Timecop.freeze(Time.parse("10 Jan 2014 10:00:00 AM UTC")) do
      assert_equal "today", DateHelper.format(Time.parse('10 Jan 2014 02:00:00 PM UTC'), @pst)
    end
  end

  test "format should return the string 'tomorrow' if the date is equal to tomorrow" do 
    Timecop.freeze(Time.parse("10 Jan 2014 17:00:00 PM UTC")) do
      assert_equal "tomorrow", DateHelper.format(Time.parse('11 Jan 2014 02:00:00 PM UTC'), @pst)          
    end
  end

  test "compare should return true if the dates are equal" do 
    time1 = Time.parse("10 Jan 2014 10:00:00 AM UTC")
    time2 = Time.parse("10 Jan 2014 10:00:00 AM UTC")

    assert DateHelper.compare(time1,time2)
  end

  test "compare should return false if the dates are not equal" do 
    time1 = Time.parse("10 Jan 2014 10:00:00 AM UTC")
    time2 = Time.parse("11 Jan 2014 10:00:00 AM UTC")

    assert !DateHelper.compare(time1,time2)
  end
end