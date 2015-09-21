class RecipientsDispatcher
  class << self
    def dispatch(recipient_attributes)
      if recipient_attributes[:organization_uniqueid].present?
        add_resources_to_org(recipient_attributes)
      else
        dispatch_from_scratch(recipient_attributes)
      end
    end

    private

    def add_resources_to_org(recipient_attributes)
      organization = Organization.find_by!(uniqueid: recipient_attributes[:organization_uniqueid])
      create_org_resources(recipient_attributes, organization, organization.default_organization_user)
    end

    def dispatch_from_scratch(recipient_attributes)
      check_preconditions(recipient_attributes)

      ActiveRecord::Base.transaction do
        create_user_and_resources(recipient_attributes)
      end
    end

    def create_user_and_resources(recipient)
      contact_point = ContactPoint.from_hash(recipient)
      user_name, organization_name, default_resource_name = fetch_names(recipient)

      # 1) Find org and user
      user = User.find_or_create_user(contact_point, user_name, organization_name: organization_name, resource_name: default_resource_name)
      organization = user.find_or_create_org(organization_name)

      # 2) Create the org-resources
      create_org_resources(recipient, organization, user.organization_user_for(organization.id))
    end

    def create_org_resources(recipient, organization, created_for)
      recipient[:resources].values.map do |resource|
        resource_name = OrganizationResource.resource_default_name(resource[:name])
        org_resource = OrganizationResource.find_or_create_within_org(organization, resource_name)

        recipient.slice(:sms, :voice, :email).merge(created_for_id: created_for.id, resource_name: org_resource.name, business_name: organization.name, organization_resource_id: org_resource.id, key: resource[:key])
      end
    end

    def normalize_recipient(recipient)
      recipient.each { |k,v| recipient[k] = v.presence }

      (recipient[:resources] || {}).values.each do |resource|
        resource.each { |k,v| resource[k] = v.presence }
      end

      recipient[:business_name] = nil if recipient[:business_name] == '(none)'
    end

    def check_preconditions recipient
      normalize_recipient recipient
      cp = recipient[:sms] || recipient[:voice] || recipient[:email]
      fail ArgumentError.new("It needs at least one contact point and one resource") unless cp && recipient[:resources].present?
    end

    def fetch_names(recipient_attrs)
      user_name = recipient_attrs.slice(:sms, :voice, :email).values.compact.first
      organization_name = recipient_attrs[:business_name].presence || user_name
      default_resource_name = OrganizationResource.resource_default_name(recipient_attrs[:resources]["0"][:name])

      [user_name, organization_name, default_resource_name]
    end
  end
end 