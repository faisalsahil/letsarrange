class CreateOrganizationResources < ActiveRecord::Migration
  def change
	create_table :organization_resources do |t|
      t.integer :organization_id
      t.integer :resource_id
      t.string :name
      t.string :visibility, default: "public"

      t.timestamps
	end

    add_index :organization_resources, [:organization_id, :resource_id]
    add_index :organization_resources, [:resource_id, :organization_id]
  end
end
