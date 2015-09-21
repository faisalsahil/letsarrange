class OrganizationUserDispatcher

  attr_accessor :org_user

  def initialize(org_user)
    @org_user = org_user
  end

  def destroy_by(author)
    ActiveRecord::Base.transaction do
      # after destroy org-user we need to check for org-user's organization's default user and
      # see if it equals to author and if it's then update with another user
      if @org_user.destroy
        org  = @org_user.organization
        user = @org_user.user
        # if there's still an org and its default user was the one we're unlinking here
        if org && org.default_user == user
          # the new org.default_user will be someone else with access to manage org
          new_default_user = (org.users - [user]).first
          org.update!(default_user: new_default_user)
        end
        true
      end
    end
  end

end