class AddAutomaticMessagesToRequest < ActiveRecord::Migration
  def change
    add_column :requests, :automatic_messages, :integer, default: 1
  end
end
