module TimeHelper
  class << self
    def between(date1, date2, tmz)
      date1 = to_array(date1, tmz)
      date2 = to_array(date2, tmz)
      start_time = date1[0]
      start_time << ":" + date1[1] if date1[1] != "00"
      start_time << date1[2] if date1[2] != date2[2]
      finish_time = date2[0]
      finish_time << ":" + date2[1] if date2[1] != "00"
      finish_time << date2[2]
      [start_time, finish_time]
    end

    def format(date, tmz)
      date1 = to_array(date, tmz)
      date = date1[0]
      date << ":" + date1[1] if date1[1] != "00"
      date << date1[2]
    end

    def compare(time1, time2)
      format(time1,"UTC") == format(time2,"UTC")
    end

    def to_array(datetime, tmz)
      datetime = datetime.in_time_zone(tmz)
      hour, time = datetime.strftime("%-I:%M%P").split(':')
      time, zone = time.scan(/[0-9]/).join, time.scan(/[a-zA-Z]/).join
      [hour,time,zone]
    end
  end
end