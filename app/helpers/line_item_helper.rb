module LineItemHelper
	def line_item_text(line, pov_user)
    "#{ line.title(pov_user) }: #{ line_item_byline(line) }"
	end

	def line_item_byline line
		request = LineItem.new_from_request(line.request)
		change = LineChange.new line: request
		change.to_sentence(line)
	end

  def mark_as_dirty line, field
    "has-changed" if line.send(field) != line.request.send(field)
  end

	def phone_for_line_item(line_item, user)
    if line_item.humanized_messages? && line_item.requested_user?(user)
      reserved_phone_for_line_item(line_item)
    else
      mapped_phone_for_line_item(line_item, user)
    end
  end

  def line_item_close_button(current_user, form)
    caption, disable_with = if form.object.closed?
                              ['Reopen', 'Reopening...'] if form.object.reopenable_by?(current_user)
                            else
                              if form.object.declinable_by?(current_user)
                                ['Decline', 'Declining...']
                              else
                                ['Close', 'Closing...']
                              end
                            end
    form.submit(caption, class: 'btn btn-block', data: { disable_with: disable_with, confirm: 'Are you sure?' }) if caption
  end

  private

  def reserved_phone_for_line_item(line_item)
    phone_caption(line_item.request.reserved_number)
  end

  def mapped_phone_for_line_item(line_item, user)
    if line_item.voice_number(user)
      mapping = user.mapping_for_entity(line_item)
      phone_caption(mapping.number_and_code) if mapping
    end
  end

  def phone_caption(phone)
    "To be connected by phone, call #{ phone }"
  end

  def line_item_requestor_label(line_item)
    if line_item.last_edited == line_item.created_by
      "#{ line_item.humanized_status.capitalize } by"
    else
      'Requestor'
    end
  end

  def line_item_responder_label(line_item)
    if line_item.last_edited == line_item.created_for
      "#{ line_item.humanized_status.capitalize } by"
    else
      'Responder'
    end
  end

  def self.date_input(line, field)
    fixed_date(line, field).try(:strftime, '%Y-%m-%dT%H:%M:%S%z')
  end

  def self.fixed_date(line, field)
    date = line.send("#{ field }_in_tmz")
    return unless date
    now = Time.now.in_time_zone(line.time_zone)
    if field == :earliest_start
      date >= now ? date : ceiled_now(now, line.time_zone)
    else
      date if date >= now
    end
  end

  def self.ceiled_now(time, time_zone)
    Time.at(time.to_i - time.to_i % 5.minutes + 5.minutes).in_time_zone(time_zone)
  end
end
