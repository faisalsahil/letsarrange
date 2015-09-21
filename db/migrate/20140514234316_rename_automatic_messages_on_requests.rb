class RenameAutomaticMessagesOnRequests < ActiveRecord::Migration
  def change
    rename_column :requests, :automatic_messages, :message_branding
  end
end
