class AddSenderNameToBroadcast < ActiveRecord::Migration
  def change
    add_column :broadcasts, :sender_name, :string
  end
end
