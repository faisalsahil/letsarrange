class CreateOrganizations < ActiveRecord::Migration
  def change
    create_table :organizations do |t|
      t.string :name
      t.string :uniqueid
      t.string :visibility, default: "public"
      t.integer :default_user_id
      
      t.timestamps
    end

    add_index :organizations, :uniqueid         
  end
end