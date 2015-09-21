class ScheduleLineItemText
  class << self
    def to_segments(start, finish, tmz)
      if finish.present?
        start.present? ? complete(start, finish, tmz) : with_no_start(finish,tmz)
      elsif start.present?
        with_no_finish(start,tmz)
      end
    end

    def to_sentence(*args)
      segments = to_segments(*args)
      if segments
        sentence = segments.values * ' '
        sentence.sub(/ and /, '-')
      end
    end

    private

    def with_no_start finish, tmz
      finish_date = DateHelper.format(finish,tmz)
      finish_time = TimeHelper.format(finish,tmz)
      { finish_date: "finishing by #{ finish_date }", finish_time: finish_time }
    end

    def with_no_finish start, tmz
      start_date = DateHelper.format(start,tmz)
      start_time = TimeHelper.format(start,tmz)
      { start_date: "at or after #{ start_date }", start_time: start_time }
    end

    def complete start, finish, tmz
      start_date = DateHelper.format(start,tmz)
      finish_date = DateHelper.format(finish,tmz)
      start_time = TimeHelper.format(start,tmz)
      finish_time = TimeHelper.format(finish,tmz)

      if TimeDifference.between(start,finish).in_hours >= 24
        {
          start_date: "between #{ start_date }",
          start_time: start_time,
          finish_date: "and #{ finish_date }",
          finish_time: finish_time
        }
      else
        formatted_start, formatted_finish = TimeHelper.between(start, finish, tmz)
        {
          start_date: "#{ 'on ' unless DateHelper.today?(start,tmz) || DateHelper.tomorrow?(start,tmz) }#{ start_date }",
          start_time: "between #{ formatted_start }",
          finish_time: "and #{ formatted_finish }"
        }
      end
    end
  end
end