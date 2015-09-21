module DateTimeHelper
  def self.format date_time, tmz
    return if date_time.blank?
    date_time.strftime("%-m/%-d") + " " + TimeHelper.format(date_time, tmz)
  end

  def self.compare dt1, dt2
    format(dt1, "UTC") == format(dt2, "UTC")
  end
end
