class CreateBroadcasts < ActiveRecord::Migration
  def change
    create_table :broadcasts do |t|
      t.integer :line_item_id
      t.integer :organization_user_id
      t.string :body
      t.timestamps
    end

    add_index :broadcasts, :line_item_id
    add_index :broadcasts, :organization_user_id
  end
end
