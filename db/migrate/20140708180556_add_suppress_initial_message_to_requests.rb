class AddSuppressInitialMessageToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :suppress_initial_message, :boolean, default: false
  end
end
