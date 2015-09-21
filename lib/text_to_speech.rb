module TextToSpeech
  OMITTED_CHARS = /[\(\)\-\_]/
  FIXED_SEGMENTS = %i(length start_date start_time finish_date finish_time ideal_date ideal_time offer)

  class << self
    def convert(text)
      text.gsub!(OMITTED_CHARS, ' ')
      text.gsub!(/[^\d\s]+\s*/) { |chunk| "#{ chunk.strip } " }
      text.gsub(/\d\s*/) { |chunk| "#{ chunk.strip }  " }.strip
    end

    def number_with_breaks(number)
      number.split(/[\(\)\-]/).select(&:present?).map { |chunk| convert(chunk) } * ' . '
    end

    def convert_broadcast(broadcast)
      segments = broadcast.line_item.to_sentence_segments(without_from: true)
      convert_segments(segments)
      reformat_length(broadcast, segments)
      {
        id: broadcast.id,
        opening: "Hi, this is lets arrange dot com .... #{ convert(broadcast.author_name) } has sent you an appointment request #{ segments[:requesting_resource] } ....",
        header: "The request is for #{ broadcast_header(segments) } ....",
        body: "The request is for #{ broadcast_main_sentence(segments) }"
      }
    end

    def duration_to_words(duration)
      hours, minutes = duration.split(':').map(&:to_i)
      ''.tap do |words|
        words << "#{ hours } hour#{ 's' unless hours == 1 }" unless hours == 0
        words << " #{ minutes } minute#{ 's' unless minutes == 1 }" unless minutes == 0
      end
    end

    private

    def broadcast_header(segments)
      [
        segments[:description] || segments[:length],
        segments[:location],
        segments[:requested_resource]
      ].compact * ' '
    end

    def broadcast_main_sentence(segments)
      segments[:comment] = "with the note .. #{ segments[:comment] }" if segments[:comment]
      segments.values * ' .... '
    end

    def reformat_length(broadcast, segments)
      length = broadcast.line_item.length.presence
      segments[:length].sub!(/#{ length }/, duration_to_words(length)) if length
    end

    def convert_segments(segments)
      segments.except(*FIXED_SEGMENTS).each { |segment, text| segments[segment] = convert(text) }
    end
  end
end