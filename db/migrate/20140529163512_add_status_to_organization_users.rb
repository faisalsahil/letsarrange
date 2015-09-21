class AddStatusToOrganizationUsers < ActiveRecord::Migration
  def change
    add_column :organization_users, :status, :integer, default: OrganizationUserState::TRUSTED
  end
end
