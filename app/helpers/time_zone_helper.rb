module TimeZoneHelper
  def self.format time_zone 
    tmz = ActiveSupport::TimeZone.new time_zone
    name = tmz.name.split("/").last.gsub(/[^A-Za-z]/,' ')
    "#{name} (#{tmz.now.formatted_offset})"
  end
end