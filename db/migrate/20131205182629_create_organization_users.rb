class CreateOrganizationUsers < ActiveRecord::Migration
  def change
  	create_table :organization_users do |t|
      t.integer :organization_id
      t.integer :user_id
      t.string :name
      t.string :visibility, default: "public"

      t.timestamps
    end

    add_index :organization_users, [:organization_id, :user_id]
    add_index :organization_users, [:user_id, :organization_id]
  end
end
