class AddBroadcastableToBroadcasts < ActiveRecord::Migration
  def change
    rename_column :broadcasts, :line_item_id, :broadcastable_id
    add_column :broadcasts, :broadcastable_type, :string
    add_index :broadcasts, :broadcastable_type

    execute "UPDATE broadcasts SET broadcastable_type='LineItem'"
  end
end