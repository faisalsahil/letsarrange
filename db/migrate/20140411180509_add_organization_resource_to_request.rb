class AddOrganizationResourceToRequest < ActiveRecord::Migration
  def self.up
    remove_column :requests, :organization_id
    add_column :requests, :organization_resource_id, :integer
    add_index :requests, :organization_resource_id                
  end

  def self.down
    add_column :requests, :orgaization_id, :integer
    remove_column :requests, :organization_resource_id
  end
end
