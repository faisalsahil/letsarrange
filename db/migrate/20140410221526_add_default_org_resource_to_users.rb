class AddDefaultOrgResourceToUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :default_resource_id
    remove_column :users, :default_org_id
    add_column :users, :default_organization_resource_id, :integer
    add_index :users, :default_organization_resource_id                
  end

  def self.down
    add_column :users, :default_resource_id, :integer
    add_column :users, :default_org_id, :integer
    remove_column :users, :default_organization_resource_id
  end
end
