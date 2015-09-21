module LetsArrange
  class TimeZone

    attr_accessor :tzinfo

    class << self
      def all
        ActiveSupport::TimeZone.all.map do |tz|
          new(tz.tzinfo)
        end
      end

      def us_zones
        ActiveSupport::TimeZone.us_zones.map do |tz|
          new(tz.tzinfo)
        end
      end
    end


    def initialize(tzinfo)
      @tzinfo = tzinfo
    end

    def identifier
      @tzinfo.identifier
    end

    def to_s
      ActiveSupport::TimeZone.new(identifier).to_s
    end

  end
end