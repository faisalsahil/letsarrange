class ChangeSenderNameToSenderNumberFromBroadcast < ActiveRecord::Migration
  def change
    rename_column :broadcasts, :sender_name, :sender_number
  end
end
