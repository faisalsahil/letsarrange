class DropPriceFromRequestsAndLineItems < ActiveRecord::Migration
  def change
    remove_column :requests, :price if column_exists?(:requests, :price)
    remove_column :line_items, :price if column_exists?(:line_items, :price)
  end
end
