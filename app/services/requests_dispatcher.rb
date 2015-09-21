class RequestsDispatcher
  # NOTE: 'author' is an instance of User (NOT a OrganizationUser)
  def self.dispatch(request_attributes, author)
    ActiveRecord::Base.transaction do
      normalize_request request_attributes

      request_attributes[:organization_resource_id] = author.default_org_resource.id if request_attributes[:organization_resource_id].blank?

      organization_id = OrganizationResource.select(:organization_id).find(request_attributes["organization_resource_id"]).organization_id
      # set OrgUser who creates the Request and who will also be the last_edited person
      org_user_id = author.organization_user_for(organization_id).id
      request_attributes[:created_by_id]  = org_user_id
      request_attributes[:last_edited_id] = org_user_id


      # set the right contact point association defined in 'privacy settings' when user is not signed in
      request_attributes[:contact_point_id] = case request_attributes[:contact_point_id].to_s
      when '-1' # first phone
        author.verified_phone.try(:id)
      when '-2' # first email
        author.contacts_email.verified.first.try(:id)
      else
        request_attributes[:contact_point_id]
      end

      request = Request.create!(request_attributes) { |r| r.assign_reserved_number(author.preferred_area_code) }

      create_broadcasts(request, author) unless request.suppress_initial_message
      request
    end
  end

  def self.strip_fields!(attrs)
    %i(description location offer).each { |attr| attrs[attr].try(:strip!) }
  end


  private

  def self.create_broadcasts(request, author)
    request.line_items.each do |li|
      author.create_mappings(li, true)
      li.create_opening_broadcast(author)
    end
  end

  def self.normalize_request(request)
    request.each { |k,v| request[k] = v.presence }
    strip_fields!(request)

    if request[:line_items_attributes]
      request[:line_items_attributes].values.each do |line|
        line.each { |k,v| line[k] = v.presence }
        strip_fields!(line)
      end
    end
  end
end