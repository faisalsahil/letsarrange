require 'test_helper'

class SchedulableTest < ActiveSupport::TestCase
  def setup
    super
    @schedulable = Request.new 
  end

  test "it responds to validate_ideal_start" do 
    assert_respond_to @schedulable, :validate_ideal_start
  end

  test "validate_ideal_start should add an error if ideal_start isn't >= than earliest_start" do
    @schedulable.earliest_start = Time.parse('10 Jan 2014 02:00:00 PM UTC')
    @schedulable.ideal_start = Time.parse('10 Jan 2014 01:00:00 PM UTC')
    @schedulable.finish_by = Time.parse('10 Jan 2014 04:00:00 PM UTC')

    @schedulable.validate_ideal_start
    assert @schedulable.errors.messages[:base].include? "Please provide a valid ideal start date"
  end

  test "validate_ideal_start should add an error if ideal_start isn't <= than finish_by" do
    @schedulable.earliest_start = Time.parse('10 Jan 2014 02:00:00 PM UTC')
    @schedulable.ideal_start = Time.parse('10 Jan 2014 05:00:00 PM UTC')
    @schedulable.finish_by = Time.parse('10 Jan 2014 04:00:00 PM UTC')

    @schedulable.validate_ideal_start
    assert @schedulable.errors.messages[:base].include? "Please provide a valid ideal start date"
  end

 test "validate_ideal_start should NOT add an error if ideal_start is <= than finish_by" do
    @schedulable.earliest_start = Time.parse('10 Jan 2014 02:00:00 PM UTC')
    @schedulable.ideal_start = Time.parse('10 Jan 2014 03:00:00 PM UTC')
    @schedulable.finish_by = Time.parse('10 Jan 2014 04:00:00 PM UTC')

    @schedulable.validate_ideal_start
    assert_nil @schedulable.errors.messages[:base]
  end

  test "it responds to validate_finish_by" do 
    assert_respond_to @schedulable, :validate_finish_by
  end

  test "validate_finish_by should add an error if finish_by is >= ideal start + length" do
    @schedulable.length = "2:25"
    @schedulable.earliest_start = Time.parse('10 Jan 2014 02:00:00 PM UTC')
    @schedulable.ideal_start = Time.parse('10 Jan 2014 03:00:00 PM UTC')
    @schedulable.finish_by = Time.parse('10 Jan 2014 04:00:00 PM UTC')
    @schedulable.validate_finish_by
    assert @schedulable.errors.messages[:base].include?("Maximum length is 1.0, since ideal start is 3pm and finish by is 4pm")
  end

  test "validate_finish_by should NOT add an error if finish_by isn't >= ideal start + length" do
    @schedulable.length = "0:25"
    @schedulable.earliest_start = Time.parse('10 Jan 2014 02:00:00 PM UTC')
    @schedulable.ideal_start = Time.parse('10 Jan 2014 04:00:00 PM UTC')
    @schedulable.finish_by = Time.parse('10 Jan 2014 05:00:00 PM UTC')

    @schedulable.validate_finish_by
    assert_nil @schedulable.errors.messages[:base]
  end
end