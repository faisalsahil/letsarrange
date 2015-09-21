class CreateRequests < ActiveRecord::Migration
  def change
    create_table :requests do |t|
      t.integer :organization_id
      t.string :description
      t.string :location
      t.datetime :ideal_start
      t.datetime :earliest_start
      t.datetime :finish_by
      t.string :time_zone, default: "UTC"
      t.string :length      
      t.string :price
      t.integer :last_edited_id
      
      t.timestamps
    end

    add_index :requests, :organization_id
    add_index :requests, :last_edited_id
  end
end
