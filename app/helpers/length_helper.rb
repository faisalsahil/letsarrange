module LengthHelper
	def self.format length_string
    return if length_string.blank?
		length_string.slice!(0) if (length_string.start_with?("0") and length_string.length > 4)
		length_string
	end

	def self.compare length1, length2
		format(length1) == format(length2)
	end	
end


