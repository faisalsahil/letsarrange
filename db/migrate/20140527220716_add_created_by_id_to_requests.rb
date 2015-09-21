class AddCreatedByIdToRequests < ActiveRecord::Migration
  def change
    add_column :requests, :created_by_id, :integer
  end
end
