class RemoveHasReceivedEmailFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :has_received_email
  end
end
