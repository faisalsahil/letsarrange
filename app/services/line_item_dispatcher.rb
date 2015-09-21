class LineItemDispatcher
  def initialize line, author
    @line = line
    @author = author
  end

  def dispatch(line_attributes)
    normalize_line(line_attributes)
    change = LineChange.new(line_attributes[:line_change].merge(line: @line.dup, user: @author))
    ActiveRecord::Base.transaction do
      create_resource(line_attributes)
      @line.assign_attributes(line_attributes.except(:organization_resource_attributes))
      @line.new_status_on_update!(@author)

      if change.substantial_changes?(@line)
        @line.update_last_edited(@author)
        @line.change_receiver(@author)
        Broadcast.create_with_user(broadcastable: @line,
                                   user: @author,
                                   body: change.to_sentence(@line, without_from: true, with_status: true))
      end

      @line
    end
  end

  private

  def create_resource line_attributes
    return if line_attributes[:organization_resource_attributes].blank?

    org = @line.requested_organization
    resource_name = line_attributes[:organization_resource_attributes][:name]
    line_attributes.except! :organization_resource_attributes
    @line.organization_resource = OrganizationResource.find_or_create_within_org(org, resource_name)
  end

  def normalize_line line_attributes
    line_attributes.each { |k,v| line_attributes[k] = v.presence }
    line_attributes[:organization_resource_attributes].try(:delete, :id)
    line_attributes[:line_change] ||= {}
    RequestsDispatcher.strip_fields!(line_attributes)
  end
end