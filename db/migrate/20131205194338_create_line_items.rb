class CreateLineItems < ActiveRecord::Migration
  def change
	create_table :line_items do |t|
      t.integer :request_id
      t.integer :organization_resource_id
      t.string :description
      t.string :location
      t.datetime :ideal_start
      t.datetime :earliest_start
      t.datetime :finish_by
      t.string :length      
      t.string :price
      t.integer :last_edited_id
      
      t.timestamps
    end

    add_index :line_items, :request_id
    add_index :line_items, :last_edited_id
  end
end
