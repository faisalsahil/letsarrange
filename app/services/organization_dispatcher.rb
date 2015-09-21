class OrganizationDispatcher

  attr_accessor :organization, :error_message

  def initialize(organization)
    @organization  = organization
  end

  def destroy_by(author)
    ActiveRecord::Base.transaction do
      # author can't destroy his/her latest organization
      unless author.multiple_organizations?
        @error_message = "Can not destroy the latest organization"
        return false
      end

      # organization can't be destroyed if it's default by other users
      unless organization.can_be_destroyed_by?(author)
        @error_message = "Organization can not be destroyed because it is the default for other(s) user(s)"
        return false
      end

      author.avoid_default_org(organization)
      organization.destroy
    end
  end

  def unlink_by(unlinker)
    if organization.users == [unlinker]
      destroy_by(unlinker)
    else
      if unlinker.multiple_organizations?
        ActiveRecord::Base.transaction do
          unlinker.avoid_default_org(organization)
          organization.avoid_default_user(unlinker)
          unlinker.organization_user_for(organization.id).destroy
        end
      else
        @error_message = "Can not unlink you from the latest organization"
        return false
      end
    end
  end
end