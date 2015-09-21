class IdealLineItemText
  attr_accessor :line_item
  delegate :earliest_start, :finish_by, :ideal_start, :time_zone, :accepted?, to: :line_item, allow_nil: true

  def initialize(line_item)
    self.line_item = line_item
  end

  def to_segments
    return unless ideal_start.present?
    segments = if finish_by.present?
                 earliest_start.present? ? complete : with_no_start
               else
                 with_no_start_and_no_finish
               end
    wrap_with_agreement(segments)
  end

  def to_sentence
    segments = to_segments
    segments.values * ' ' if segments
  end

  private 

  def with_no_start
    {}.tap do |segments|
      segments[:ideal_date] = ideal_date unless DateHelper.today?(finish_by, time_zone)
      segments[:ideal_time] = ideal_time
    end
  end

  def with_no_start_and_no_finish
    {
      ideal_date: ideal_date,
      ideal_time: ideal_time
    }
  end

  def complete
    if TimeDifference.between(earliest_start, finish_by).in_hours >= 24
      with_no_start_and_no_finish
    else
      { ideal_time: ideal_time }
    end
  end

  def ideal_date
    DateHelper.format(ideal_start, time_zone)
  end

  def ideal_time
    TimeHelper.format(ideal_start, time_zone)
  end

  def wrap_with_agreement(segments)
    first_segment = segments.keys.first
    last_segment = segments.keys.last
    if accepted?
      segments[first_segment] = "agreed #{ segments[first_segment] }"
    else
      segments[first_segment] = "(ideally #{ segments[first_segment] }"
      segments[last_segment] = "#{ segments[last_segment] })"
    end
    segments
  end
end