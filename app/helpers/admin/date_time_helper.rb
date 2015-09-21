module Admin
    module DateTimeHelper
      def self.format(date, tmz)
         date_string = DateHelper.format(date, tmz)
         date_string.sub!(/^on\s/, '')
      	 "#{ date_string } #{ date.strftime("%-I:%M%P") }"
      end
    end
end