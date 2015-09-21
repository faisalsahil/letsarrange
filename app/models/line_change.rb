class LineChange
  include ActiveModel::Model

  attr_accessor :comment, :line, :user

  def to_sentence(new_line, without_from: false, with_status: false)
    sentence = []
    if with_status && status_changed?(new_line)
      if @line.systemized_messages?
        sentence << "[#{ new_line.humanized_status }]"
      else
        sentence << "#{ new_line.humanized_wording_status }"
      end
    end
    sentence << "#{@user.name}:" if @user && !without_from

    description_text = new_line.description.present? ? "#{new_line.description}" : "(removed for what)"
    sentence << description_text if @line.description != new_line.description

    location_text = new_line.location.present? ? "at #{new_line.location}" : "(removed where)"
    sentence << location_text if @line.location != new_line.location

    sentence << "with #{new_line.organization_resource.name}" if organization_resource_different?(new_line)

    length_text = new_line.length.present? ? "for #{LengthHelper.format(new_line.length)}" : "(removed how long)"
    sentence << length_text unless LengthHelper.compare(@line.length, new_line.length)

    if dates_blank?(new_line)
      sentence << "(removed start and finish)" unless dates_blank?
    else
      sentence << ScheduleLineItemText.to_sentence(new_line.earliest_start,new_line.finish_by, new_line.time_zone) if dates_different?(new_line)
    end

    if new_line.ideal_start.present?
      sentence << IdealLineItemText.new(new_line).to_sentence if show_ideal_start?(new_line)
    else
      sentence << "(removed ideal start)" if @line.ideal_start.present?
    end

    offer_text = new_line.offer.present? ? "offering #{ new_line.offer }" : '(removed offer)'
    sentence << offer_text if @line.offer != new_line.offer

    sentence.compact!
    if @comment.present?
      sentence << '-' if sentence.present?
      sentence << @comment
    end
    (sentence * ' ').strip.presence unless !without_from && sentence.length == 1
  end

  def substantial_changes?(updated_record)
    comment.present? || fields_changed?(updated_record)
  end

  private

  def fields_changed?(updated_record)
    ignored_fields = %w(id created_at updated_at)
    @line.attributes.except(*ignored_fields) != updated_record.attributes.except(*ignored_fields)
  end

  def status_changed?(updated_record)
    @line.status != updated_record.status
  end

  def show_ideal_start?(updated_record)
    updated_record.ideal_start != @line.ideal_start || (updated_record.accepted? && status_changed?(updated_record))
  end

  def dates_different? new_line
    !DateTimeHelper.compare(@line.finish_by, new_line.finish_by) or
     !DateTimeHelper.compare(@line.earliest_start, new_line.earliest_start)
  end

  def dates_blank? line=nil
    line ||= @line
    line.finish_by.blank? and line.earliest_start.blank?
  end

  def organization_resource_different? new_line
    return unless new_line.organization_resource and @line.organization_resource
    @line.organization_resource.name != new_line.organization_resource.name
  end
end
