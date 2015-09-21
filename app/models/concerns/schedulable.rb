module Schedulable
  extend ActiveSupport::Concern

  included do
    before_validation :validate_ideal_start, :validate_finish_by
  end

  def validate_ideal_start
    return if ideal_start.blank? or !dates_present?

    unless (earliest_start..finish_by).cover?(ideal_start)
        self.errors[:base] << "Please provide a valid ideal start date"
    end
  end

  def validate_finish_by 
    return unless dates_present?
    
    t = Time.parse(length || "0:00")
    baseline = ideal_start || earliest_start

    max_length_message = TimeDifference.between(baseline, finish_by).in_hours
    ideal_start_message = TimeHelper.format(baseline, "UTC")
    finish_by_message =  TimeHelper.format(finish_by, "UTC")

    unless finish_by >= (baseline + t.hour.hours + t.min.minutes + t.sec.seconds) 
      self.errors[:base] << "Maximum length is #{max_length_message}, since ideal start is #{ideal_start_message} and finish by is #{finish_by_message}"
    end
  end

  def dates_present?
    earliest_start.present? and finish_by.present?
  end
end