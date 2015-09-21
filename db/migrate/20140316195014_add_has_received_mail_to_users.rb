class AddHasReceivedMailToUsers < ActiveRecord::Migration
  def change
    add_column :users, :has_received_email, :boolean, default: false
  end
end
