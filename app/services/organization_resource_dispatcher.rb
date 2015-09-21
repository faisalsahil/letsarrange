class OrganizationResourceDispatcher

  attr_accessor :org_resource, :error_message

  def initialize(org_resource)
    @org_resource  = org_resource
    @error_message = ''
  end

  def destroy_by(author)
    ActiveRecord::Base.transaction do
      # author can't destroy his/her latest org_resource
      if author.managed_org_resources.size <= 1
        @error_message = "Resource cannot be unlinked"
        return false
      end

      # org_resource can't be destroyed if it's default by other users
      unless @org_resource.can_be_unlinked_by?(author)
        @error_message = "Resource can not be unlinked because it is the default for other(s) user(s)"
        return false
      end

      # update author's default org_resource if it was the one we're destroying
      if author.default_org_resource == @org_resource
        # the new default org-resource will the lowest (first) org-resource for current org
        # OR the lowest (first) org-resource with access for author
        new_org_resource = (@org_resource.organization.organization_resources - [@org_resource]).first ||
                           (author.managed_org_resources - [@org_resource]).first
        author.update!(default_org_resource: new_org_resource)
      end

      @org_resource.destroy
    end
  end

end