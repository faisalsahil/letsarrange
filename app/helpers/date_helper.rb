module DateHelper
	def self.format date, tmz
		return if date.blank?
    return "today" if today?(date,tmz)
		return "tomorrow" if tomorrow?(date,tmz)

		date.strftime("%-m/%-d")
	end

	def self.compare date1, date2
		date1.strftime("%-m/%-d") == date2.strftime("%-m/%-d")
	end

	def self.today? date,tmz
		date.in_time_zone(tmz).strftime("%-m/%-d") == Time.now.in_time_zone(tmz).strftime("%-m/%-d")
	end

	def self.tomorrow? date, tmz
		date.in_time_zone(tmz).strftime("%-m/%-d") == Time.now.tomorrow.in_time_zone(tmz).strftime("%-m/%-d")
	end

	def self.created_at_for_broadcast(broadcast)
    I18n.l(broadcast.created_at_in_tmz, format: :for_broadcast)
	end
end