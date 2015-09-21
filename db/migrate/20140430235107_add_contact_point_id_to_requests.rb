class AddContactPointIdToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :contact_point_id, :integer
  end
end
